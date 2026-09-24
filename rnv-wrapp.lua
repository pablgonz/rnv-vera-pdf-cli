#!/usr/bin/env texlua

local WRAPPER_VERSION = "1.0"

-- 1. Detección del SO y ubicación del binario RNV
local is_windows = package.config:sub(1,1) == '\\'
local rnv_bin = is_windows and "rnv.exe" or "rnv"
local script_dir = arg[0]:match("(.*[/\\])") or "./"
local rnv_path = script_dir .. rnv_bin

local rnv_check = io.open(rnv_path, "r")
if not rnv_check then
    io.stderr:write("Error: rnv binary not found at '" .. rnv_path .. "'\n")
    os.exit(1)
end
rnv_check:close()

-- Quoting helper, different per OS -- on POSIX, single quotes block
-- ALL expansion ($, `, glob); on Windows there's no real equivalent
-- against %VAR%, so it warns if one appears.
local function quote_arg(v)
    if is_windows then
        if v:find("%%") then
            io.stderr:write("[WARNING] argument contains '%': "
                .. v .. " -- cmd.exe may expand it as an environment variable.\n")
        end
        return '"' .. v:gsub('"', '\\"') .. '"'
    else
        return "'" .. v:gsub("'", "'\\''") .. "'"
    end
end

-- Corre "rnv -v" (sin esquema, pelado) y devuelve solo el numero,
-- para el banner de ayuda y --version -- nunca fijo a mano.
local function get_rnv_version()
    local handle = io.popen(quote_arg(rnv_path) .. " -v 2>&1", "r")
    local rnv_output = handle and handle:read("*a") or ""
    if handle then handle:close() end
    return rnv_output:match("rnv version (%S+)") or "unknown"
end

-- 2. Diccionario de esquemas válidos
local valid_schemas = {
    ["auto"]     = "latex-document-switch.rnc",
    ["pdfua2"]   = "document-pdf-ua2.rnc",
    ["pdfua1"]   = "document-pdf-ua1.rnc",
    ["latexua2"] = "latex-document.rnc",
    ["latexua1"] = "latex-document17.rnc",
    ["none"]     = "none.rnc"
}

-- 3. Estado del parser (auto es el valor por defecto)
local config = {
    path = nil,
    schema_key = "auto",
    strict = false,
    help = false,
    version = false
}
local rnv_flags = {}
local rnv_files = {}

-- 4. Parser de intercepción cli
local i = 1
while i <= #arg do
    local current = arg[i]

    if current == "--help" then
        config.help = true

    elseif current == "--version" then
        config.version = true

    elseif current == "--strict" then
        config.strict = true

    elseif current == "--path" then
        if not arg[i+1] then
            io.stderr:write("Error: option '--path' requires a value\n")
            os.exit(1)
        end
        i = i + 1
        config.path = arg[i]
    elseif current:match("^%-%-path=(.*)") then
        config.path = current:match("^%-%-path=(.*)")

    elseif current == "--schema" then
        if not arg[i+1] then
            io.stderr:write("Error: option '--schema' requires a value\n")
            os.exit(1)
        end
        i = i + 1
        config.schema_key = arg[i]
    elseif current:match("^%-%-schema=(.*)") then
        config.schema_key = current:match("^%-%-schema=(.*)")

    else
        if current:sub(1,2) == "--" then
            -- Ninguna bandera real de RNV usa doble guion (todas son
            -- -q, -n, -p, -c, -s, -v, -h); si llego hasta aca sin
            -- matchear ninguna opcion conocida del wrapper, es un
            -- error del usuario, no algo para reenviarle a RNV.
            io.stderr:write("Error: unrecognized option '" .. current .. "'\n")
            os.exit(1)
        elseif current:sub(1,1) == "-" then
            -- Solo estas siete son banderas reales de RNV (ver su
            -- propia ayuda); cualquier otra cosa con un solo guion es
            -- tambien un error del usuario, no algo para reenviarle.
            if current:match("^%-[qnpcsv]$") or current == "-h" or current == "-help" then
                table.insert(rnv_flags, current)
                if current == "-n" and i < #arg and not arg[i+1]:match("^%-") then
                    i = i + 1
                    table.insert(rnv_flags, arg[i])
                end
            else
                io.stderr:write("Error: unrecognized option '" .. current .. "'\n")
                os.exit(1)
            end
        else
            -- Si no, es el documento XML
            table.insert(rnv_files, current)
        end
    end

    i = i + 1
end

-- 5. Cero argumentos en total: mostrar ayuda, salvo que stdin este
-- siendo redirigido (pipe/archivo). Si se paso CUALQUIER argumento
-- (una bandera valida, --schema, lo que sea), no se interviene:
-- se arma el comando y se deja que rnv se comporte como le
-- corresponde, incluido quedar esperando stdin si no hay documento
-- -- eso es su comportamiento normal y documentado, no algo que el
-- wrapper deba adivinar.
if #arg == 0 then
    local ffi = require("ffi")
    ffi.cdef[[
        int isatty(int fd);
        int _isatty(int fd);
    ]]
    local is_tty
    if ffi.os == "Windows" then
        is_tty = ffi.C._isatty(0) ~= 0
    else
        is_tty = ffi.C.isatty(0) ~= 0
    end
    if is_tty then
        config.help = true
    end
end

-- 6. Ayuda
if config.help then
    print("rnv-wrapp v" .. WRAPPER_VERSION .. " - Wrapper for Relax NG Validator v"
        .. get_rnv_version() .. " under TeX Live")
    print([[
Syntax
$ rnv-wrapp [<wrapper options>] [<rnv options>] document.xml

Description
  rnv-wrapp is a Lua script that automates the process of validating
  tagged PDF documents generated by LaTeX using show-pdf-tags and rnv.
  This wrapper performs validation using the official schema provided
  by show-tag-pdf in TeX Live. By default, it validates against PDF/UA-2
  and returns "PASS" or "FAIL", unless the --strict option is used.

Options
  --help            Displays this usage summary and exits.
  --schema=<alias>  Injects the corresponding validation schema same ones
                    used at https://texlive.net/showtags (default: auto).
                    Valid options: auto, pdfua2, pdfua1, latexua2, latexua1, none.
  --path=<path>     Overrides the base directory where schemas are located.
  --strict          If validation fails, exits with an error code (halts processes).
                    Without this, errors are printed but it exits cleanly (code 0).
  --version         Prints the wrapper and rnv version numbers and exits.

RNV Options
  -q                names of files being processed are not printed; in error
                    messages, expected elements and attributes are not listed;
  -n <num>          sets the maximum number of reported expected elements and
                    attributes, -q sets this to 0 and can be overriden;
  -p                copies the input to the output;
  -c                if the only argument is a grammar, checks the grammar and
                    exits;
  -s                uses less memory and runs slower;
  -v                prints version number;
  -h, -help         displays usage summary and exits (note: single dash --
                    rnv does not recognize "--help").

Note: If no documents are specified, RNV attempts to read the XML document
from the standard input.

Example
$ show-tag-pdf --xml test.pdf | rnv-wrapp
  It will process the file test.pdf using show-tag-pdf and validate it
  against PDF/UA-2 using rnv, returning "PASS" or "FAIL".

Issues and reports
Repository : https://github.com/pablgonz/rnv-vera-pdf-cli
Bug tracker: https://github.com/pablgonz/rnv-vera-pdf-cli/issues
Copyright(C) 2026 by Pablo González L <pablgonz<at>educarchile.cl>
]])
    os.exit(0)
end

-- 6b. --version: corre "rnv -v" (sin esquema, pelado) para capturar
-- su numero de version en vivo, en vez de tenerlo fijo a mano.
if config.version then
    print("rnv-wrapp v" .. WRAPPER_VERSION .. " - Wrapper for Relax NG Validator v"
        .. get_rnv_version() .. " under TeX Live")
    os.exit(0)
end

-- 7. Resolución de rutas
-- -v y -h no necesitan esquema para hacer su trabajo (rnv las
-- responde solo con el uso/version y corta limpio) -- si son las
-- UNICAS banderas dadas y no hay documento, no se inyecta ningun
-- esquema, para que rnv corra "pelado" y replique ese corte limpio.
local only_informational = true
for _, v in ipairs(rnv_flags) do
    if v ~= "-v" and v ~= "-h" and v ~= "-help" then
        only_informational = false
        break
    end
end
local skip_schema = only_informational and #rnv_flags > 0 and #rnv_files == 0

local resolved_schema = nil

if config.schema_key and not skip_schema then
    local filename = valid_schemas[config.schema_key]

    if not filename then
        print("ERROR: Schema alias '" .. config.schema_key .. "' is not valid.")
        os.exit(1)
    end

    local target_dir = config.path

    if not target_dir or target_dir == "" then
        if not kpse then
            io.stderr:write("Error: kpse is not available -- is this running under texlua from a TeX Live installation?\n")
            os.exit(1)
        end
        kpse.set_program_name("luatex")
        local texmfdist = kpse.expand_var("$TEXMFDIST")
        target_dir = texmfdist .. "/doc/support/show-pdf-tags"
    end

    local clean_path = target_dir:gsub("[/\\]$", "")
    resolved_schema = clean_path .. "/" .. filename
end

-- 8. Ensamblaje (rnv [opciones_rnv] esquema xml)
local cmd = quote_arg(rnv_path)

for _, v in ipairs(rnv_flags) do
    cmd = cmd .. ' ' .. quote_arg(v)
end

if resolved_schema then
    cmd = cmd .. ' ' .. quote_arg(resolved_schema)
end

for _, v in ipairs(rnv_files) do
    cmd = cmd .. ' ' .. quote_arg(v)
end

-- 9. Ejecución y Captura de Salida
local full_cmd = cmd .. " 2>&1"
local handle = io.popen(full_cmd, "r")
local output = handle:read("*a")
local success, _, exit_code = handle:close()

output = output:gsub("%s+$", "")

if skip_schema then
    -- Modo informativo (-v/-h solas, sin documento): no hay nada que
    -- validar, asi que PASS/FAIL no tiene sentido -- se muestra la
    -- salida de rnv tal cual, y se sale con su mismo codigo.
    if output ~= "" then
        print(output)
    end
    os.exit(exit_code or 0)
end

if success and exit_code == 0 then
    print("PASS")

    if output ~= "" then
        print(output)
    end
    os.exit(0)
else
    print("FAIL:")
    if output ~= "" then
        print(output)
    else
        print("Unknown validation error (Exit code: " .. tostring(exit_code) .. ")")
    end

    if config.strict then
        os.exit(exit_code or 1)
    else
        os.exit(0)
    end
end
