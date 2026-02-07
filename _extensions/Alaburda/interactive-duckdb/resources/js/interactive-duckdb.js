// Interactive DuckDB - Post-processing script
(function() {
  // Move output elements to proper position within the container
  document.addEventListener('DOMContentLoaded', function() {
    const containers = document.querySelectorAll('div.interactive-duckdb');
    containers.forEach(container => {
      const output = container.querySelector('div.duckdb-output');
      if (output) {
        // Ensure output is at the end
        container.appendChild(output);
      }
    });
    
    // For revealjs: Handle line numbers for editable code
    const revealContainers = document.querySelectorAll('.reveal div.interactive-duckdb');
    revealContainers.forEach(container => {
      const pre = container.querySelector('pre.sourceCode');
      const code = container.querySelector('code.sourceCode');
      if (code && code.hasAttribute('contenteditable')) {
        if (pre && pre.classList.contains('numberSource')) {
          pre.classList.remove('numberSource');
        }
      }
    });
  });
})();
