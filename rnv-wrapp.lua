#!/usr/bin/env texlua

-- 1. Detección del SO y ubicación del binario RNV
local is_windows = package.config:sub(1,1) == '\\'
local rnv_bin = is_windows and "rnv.exe" or "rnv"
local script_dir = arg[0]:match("(.*[/\\])") or "./"
local rnv_path = script_dir .. rnv_bin

-- 2. Diccionario de esquemas válidos
local valid_schemas = {
    ["auto"]     = "latex-document-switch.rnc",
    ["pdfua2"]   = "document-pdf-ua2.rnc",
    ["pdfua1"]   = "document-pdf-ua1.rnc",
    ["latexua2"] = "latex-document.rnc",
    ["latexua1"] = "latex-document17.rnc",
    ["none"]     = "none.rnc"
}

-- 3. Estado del parser
local config = {
    path = nil,
    schema_key = nil,
    strict = false,
    help = false
}
local rnv_flags = {}
local rnv_files = {}

-- 4. Parser de intercepción estricta
local i = 1
while i <= #arg do
    local current = arg[i]

    if current == "--help" or current == "-h" then
        config.help = true

    elseif current == "--strict" then
        config.strict = true

    elseif current == "--path" then
        i = i + 1
        config.path = arg[i]
    elseif current:match("^%-%-path=(.*)") then
        config.path = current:match("^%-%-path=(.*)")

    elseif current == "--schema" then
        i = i + 1
        config.schema_key = arg[i]
    elseif current:match("^%-%-schema=(.*)") then
        config.schema_key = current:match("^%-%-schema=(.*)")

    else
        -- Si empieza con "-", es una bandera nativa de RNV
        if current:sub(1,1) == "-" then
            table.insert(rnv_flags, current)
            if current == "-n" and i < #arg and not arg[i+1]:match("^%-") then
                i = i + 1
                table.insert(rnv_flags, arg[i])
            end
        else
            -- Si no, es el documento XML
            table.insert(rnv_files, current)
        end
    end

    i = i + 1
end

-- 5. Pantalla de Ayuda
if config.help then
    print([[
RNV Wrapper for TeX Live
Usage: rnv-wrap [wrapper_options] [rnv_options] document.xml

Wrapper Options:
  --schema=<alias>   Injects the corresponding validation schema.
                     Valid options: auto, pdfua2, pdfua1, latexua2, latexua1, none.
  --path=<path>      Overrides the base directory where schemas are located.
  --strict           If validation fails, exits with an error code (halts processes).
                     Without this, errors are printed but it exits cleanly (code 0).

Native RNV Options:
  -q                 names of files being processed are not printed; in error
                     messages, expected elements and attributes are not listed;
  -n <num>           sets the maximum number of reported expected elements and
                     attributes, -q sets this to 0 and can be overriden;
  -p                 copies the input to the output;
  -c                 if the only argument is a grammar, checks the grammar and
                     exits;
  -s                 uses less memory and runs slower;
  -v                 prints version number;
  -h, --help         displays usage summary and exits.

Note: If no documents are specified, RNV attempts to read the XML document
from the standard input.
]])
    os.exit(0)
end

-- 6. Resolución de rutas
local resolved_schema = nil

if config.schema_key then
    local filename = valid_schemas[config.schema_key]

    if not filename then
        print("ERROR: Schema alias '" .. config.schema_key .. "' is not valid.")
        os.exit(1)
    end

    local target_dir = config.path

    if not target_dir or target_dir == "" then
        kpse.set_program_name("luatex")
        local texmfdist = kpse.expand_var("$TEXMFDIST")
        target_dir = texmfdist .. "/doc/support/show-pdf-tags"
    end

    local clean_path = target_dir:gsub("[/\\]$", "")
    resolved_schema = clean_path .. "/" .. filename
end

-- 7. Ensamblaje estricto (rnv [opciones_rnv] esquema xml)
local cmd = '"' .. rnv_path .. '"'

for _, v in ipairs(rnv_flags) do
    cmd = cmd .. ' "' .. v:gsub('"', '\\"') .. '"'
end

if resolved_schema then
    cmd = cmd .. ' "' .. resolved_schema .. '"'
end

for _, v in ipairs(rnv_files) do
    cmd = cmd .. ' "' .. v:gsub('"', '\\"') .. '"'
end

-- 8. Ejecución y Captura de Salida
-- Redirigimos stderr a stdout (2>&1) para atrapar los mensajes de error de RNV
local full_cmd = cmd .. " 2>&1"
local handle = io.popen(full_cmd, "r")
local output = handle:read("*a")
local success, _, exit_code = handle:close()

-- Limpiar saltos de línea extra al final del output
output = output:gsub("%s+$", "")

if success or exit_code == 0 then
    -- Si el código de salida es 0, el XML es válido.
    print("Valid")

    -- Si RNV escupió alguna advertencia aunque haya sido exitoso, la mostramos
    if output ~= "" then
        print(output)
    end
    os.exit(0)
else
    -- Si falló, imprimimos "Invalid:" seguido del reporte real de RNV
    print("Invalid:")
    if output ~= "" then
        print(output)
    else
        print("Unknown validation error (Exit code: " .. tostring(exit_code) .. ")")
    end

    -- Lógica del modo Estricto
    if config.strict then
        os.exit(exit_code or 1) -- Rompe la cadena de comandos (devuelve error al SO)
    else
        os.exit(0) -- Tolera el error: muestra el texto pero dice que el script terminó "bien"
    end
end
