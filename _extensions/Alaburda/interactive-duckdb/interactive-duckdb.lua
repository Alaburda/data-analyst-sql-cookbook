-- Interactive DuckDB Extension for Quarto
-- Enables running DuckDB SQL queries interactively in Quarto HTML documents

str = pandoc.utils.stringify

-- Add HTML dependencies (CSS and JS files)
local function ensureHtmlDeps()
  quarto.doc.add_html_dependency({
    name = "interactive-duckdb",
    version = "1.0.0",
    scripts = {
      {
        path = "resources/js/interactive-duckdb.js",
        afterBody = true
      }
    },
    stylesheets = {"resources/css/interactive-duckdb.css"}
  })
end

-- Add DuckDB WASM scripts to the document header
local function add_duckdb_scripts()
  quarto.doc.include_text(
    "in-header",
    [[
<script type="module">
  import * as duckdb from 'https://cdn.jsdelivr.net/npm/@duckdb/duckdb-wasm@1.28.0/+esm';
  
  // Global DuckDB instance management
  window.duckdbModule = duckdb;
  window.duckdbInstances = {};
  window.duckdbReady = {};
  window.duckdbInitializing = {};
  
  window.initDuckDB = async function(dbName, dataFiles) {
    if (window.duckdbReady[dbName]) {
      return window.duckdbInstances[dbName];
    }
    
    // Prevent multiple simultaneous initializations
    if (window.duckdbInitializing[dbName]) {
      // Wait for existing initialization
      while (window.duckdbInitializing[dbName]) {
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      return window.duckdbInstances[dbName];
    }
    
    window.duckdbInitializing[dbName] = true;
    
    try {
      const JSDELIVR_BUNDLES = duckdb.getJsDelivrBundles();
      const bundle = await duckdb.selectBundle(JSDELIVR_BUNDLES);
      
      const worker_url = URL.createObjectURL(
        new Blob([`importScripts("${bundle.mainWorker}");`], {type: 'text/javascript'})
      );
      
      const worker = new Worker(worker_url);
      const logger = new duckdb.ConsoleLogger();
      const db = new duckdb.AsyncDuckDB(logger, worker);
      await db.instantiate(bundle.mainModule, bundle.pthreadWorker);
      URL.revokeObjectURL(worker_url);
      
      const conn = await db.connect();
      
      // Load data files if provided
      // dataFiles is an array of {url, format, tableName} objects
      if (dataFiles && dataFiles.length > 0) {
        for (const file of dataFiles) {
          try {
            const { url, format, tableName } = file;
            if (!url || url.length === 0) continue;
            
            if (format === 'duckdb' || format === 'db') {
              const response = await fetch(url);
              const arrayBuffer = await response.arrayBuffer();
              await db.registerFileBuffer('db.duckdb', new Uint8Array(arrayBuffer));
              await conn.query(`ATTACH 'db.duckdb' AS filedb`);
              await conn.query(`USE filedb`);
            } else if (format === 'parquet') {
              console.log('Loading parquet file:', url, 'as table:', tableName);
              const response = await fetch(url);
              if (!response.ok) throw new Error(`Failed to fetch ${url}: ${response.status}`);
              const arrayBuffer = await response.arrayBuffer();
              const fileName = `${tableName}.parquet`;
              await db.registerFileBuffer(fileName, new Uint8Array(arrayBuffer));
              await conn.query(`CREATE TABLE ${tableName} AS SELECT * FROM parquet_scan('${fileName}')`);
              console.log('Table', tableName, 'created successfully');
            } else if (format === 'csv') {
              console.log('Loading CSV file:', url, 'as table:', tableName);
              const response = await fetch(url);
              if (!response.ok) throw new Error(`Failed to fetch ${url}: ${response.status}`);
              const arrayBuffer = await response.arrayBuffer();
              const fileName = `${tableName}.csv`;
              await db.registerFileBuffer(fileName, new Uint8Array(arrayBuffer));
              await conn.query(`CREATE TABLE ${tableName} AS SELECT * FROM read_csv_auto('${fileName}')`);
            } else if (format === 'json') {
              console.log('Loading JSON file:', url, 'as table:', tableName);
              const response = await fetch(url);
              if (!response.ok) throw new Error(`Failed to fetch ${url}: ${response.status}`);
              const arrayBuffer = await response.arrayBuffer();
              const fileName = `${tableName}.json`;
              await db.registerFileBuffer(fileName, new Uint8Array(arrayBuffer));
              await conn.query(`CREATE TABLE ${tableName} AS SELECT * FROM read_json_auto('${fileName}')`);
            } else if (format === 'sql') {
              const response = await fetch(url);
              const sqlScript = await response.text();
              await conn.query(sqlScript);
            }
          } catch (e) {
            console.error('Error loading file:', file, e);
          }
        }
      }
      
      window.duckdbInstances[dbName] = { db, conn };
      window.duckdbReady[dbName] = true;
      
      return { db, conn };
    } finally {
      window.duckdbInitializing[dbName] = false;
    }
  }
  
  window.runDuckDBQuery = async function(dbName, query, outputEl, queryEl) {
    try {
      const { conn } = window.duckdbInstances[dbName];
      const actualQuery = queryEl ? queryEl.textContent : query;
      
      const result = await conn.query(actualQuery);
      const rows = result.toArray();
      
      if (rows.length === 0) {
        outputEl.innerHTML = '<div class="duckdb-message">Query executed successfully. No results to display.</div>';
        return;
      }
      
      // Get column names from the schema
      const columns = result.schema.fields.map(f => f.name);
      
      // Build HTML table
      let html = '<table class="duckdb-result-table"><thead><tr>';
      columns.forEach(col => {
        html += '<th>' + escapeHtml(col) + '</th>';
      });
      html += '</tr></thead><tbody>';
      
      rows.forEach(row => {
        html += '<tr>';
        columns.forEach(col => {
          const value = row[col];
          html += '<td>' + escapeHtml(value !== null && value !== undefined ? String(value) : 'NULL') + '</td>';
        });
        html += '</tr>';
      });
      
      html += '</tbody></table>';
      html += '<div class="duckdb-row-count">' + rows.length + ' row(s)</div>';
      
      outputEl.innerHTML = html;
    } catch (e) {
      outputEl.innerHTML = '<div class="duckdb-error">Error: ' + escapeHtml(e.message) + '</div>';
    }
  }
  
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
</script>
]]
  )
end


-- Extract database configurations from document metadata
function get_dbs(databases)
  return {
    Meta = function(m)
      if m.databases then
        for key, val in ipairs(m.databases) do
          -- Handle editable: check if explicitly set to false
          local is_editable = true
          if val.editable ~= nil then
            local editable_str = str(val.editable)
            if editable_str == "false" or val.editable == false then
              is_editable = false
            end
          end
          
          -- Build files array from either 'files' list or single 'path'
          local files = {}
          if val.files then
            -- Multiple files specified
            for _, f in ipairs(val.files) do
              table.insert(files, {
                url = str(f.path),
                format = f.format and str(f.format) or "parquet",
                tableName = str(f.name)
              })
            end
          elseif val.path and str(val.path) ~= "" then
            -- Single file (legacy format)
            table.insert(files, {
              url = str(val.path),
              format = val.format and str(val.format) or "sql",
              tableName = str(val.name)
            })
          end
          
          local db = {
            ["name"] = str(val.name),
            ["files"] = files,
            ["class"] = str(val.name),
            ["editable"] = is_editable
          }
          table.insert(databases, db)
        end
      end
    end
  }
end


-- Wrap interactive SQL code blocks in a div
function CodeBlock(cb)
  if cb.classes:includes('interactive') then
    local div = pandoc.Div(cb, {class = "interactive-duckdb"})
    return div
  end
end


-- Main processing for HTML output
if quarto.doc.is_format("html:js") then
  function Pandoc(doc)
    
    add_duckdb_scripts()
    ensureHtmlDeps()
    
    local databases = {}
    doc:walk(get_dbs(databases))
    
    -- Add initialization code for each database
    local init_scripts = {}
    for key, val in ipairs(databases) do
      local editable = val.editable and 'true' or 'false'
      
      -- Build JSON array for files
      local files_json = "["
      for i, f in ipairs(val.files) do
        if i > 1 then files_json = files_json .. "," end
        files_json = files_json .. string.format(
          '{url:%q,format:%q,tableName:%q}',
          f.url, f.format, f.tableName
        )
      end
      files_json = files_json .. "]"
      
      local init_script = string.format([[
<script>
(function() {
  const dbName = %q;
  const dataFiles = %s;
  const editable = %s;
  const selector = 'div.interactive-duckdb pre.%s code';
  
  document.addEventListener('DOMContentLoaded', function() {
    // Find all code blocks for this database
    const codeBlocks = document.querySelectorAll(selector);
    codeBlocks.forEach((codeEl, idx) => {
      const container = codeEl.closest('.interactive-duckdb');
      if (!container) return;
      
      // Make code editable if enabled
      if (editable) {
        codeEl.setAttribute('contenteditable', 'true');
        codeEl.setAttribute('spellcheck', 'false');
      }
      
      // Create output container
      let outputEl = container.querySelector('.duckdb-output');
      if (!outputEl) {
        outputEl = document.createElement('div');
        outputEl.className = 'duckdb-output';
        container.appendChild(outputEl);
      }
      
      // Create run button
      let btnContainer = container.querySelector('.duckdb-btn-container');
      if (!btnContainer) {
        btnContainer = document.createElement('div');
        btnContainer.className = 'duckdb-btn-container';
        
        const runBtn = document.createElement('button');
        runBtn.className = 'duckdb-run-btn';
        runBtn.textContent = '▶ Run';
        runBtn.addEventListener('click', async function() {
          outputEl.innerHTML = '<div class="duckdb-loading">Initializing DuckDB...</div>';
          try {
            await initDuckDB(dbName, dataFiles);
            await runDuckDBQuery(dbName, '', outputEl, codeEl);
          } catch (e) {
            outputEl.innerHTML = '<div class="duckdb-error">Error: ' + e.message + '</div>';
          }
        });
        
        btnContainer.appendChild(runBtn);
        container.insertBefore(btnContainer, outputEl);
      }
      
      // Run query on Ctrl+Enter / Cmd+Enter
      codeEl.addEventListener('keydown', async function(e) {
        if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
          e.preventDefault();
          outputEl.innerHTML = '<div class="duckdb-loading">Initializing DuckDB...</div>';
          try {
            await initDuckDB(dbName, dataFiles);
            await runDuckDBQuery(dbName, '', outputEl, codeEl);
          } catch (e) {
            outputEl.innerHTML = '<div class="duckdb-error">Error: ' + e.message + '</div>';
          }
        }
      });
    });
  });
})();
</script>
]], val.name, files_json, editable, val.class)
      
      table.insert(init_scripts, init_script)
    end
    
    -- Add all initialization scripts
    for _, script in ipairs(init_scripts) do
      local script_html = pandoc.RawBlock('html', script)
      table.insert(doc.blocks, script_html)
    end
    
    return doc
  end
end
