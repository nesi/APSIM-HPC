document.addEventListener('DOMContentLoaded', function() {
    // Find all calculator containers
    const containers = document.querySelectorAll('.calculator-container');
    
    containers.forEach(container => {
      const root = ReactDOM.createRoot(container);
      root.render(React.createElement(RuntimeCalculator));
    });
  });