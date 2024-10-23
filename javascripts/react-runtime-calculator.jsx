const RuntimeCalculator = () => {
    const [soilSamples, setSoilSamples] = React.useState('');
    const [weatherFiles, setWeatherFiles] = React.useState('');
  
    // Constants
    const SECONDS_PER_FILE = 30;
    const MAX_HOURS_PER_SET = 24;
    const SECONDS_PER_HOUR = 3600;
  
    // Calculate total files and runtime
    const totalFiles = soilSamples && weatherFiles ? soilSamples * weatherFiles : 0;
    const totalSeconds = totalFiles * SECONDS_PER_FILE;
    const totalHours = (totalSeconds / SECONDS_PER_HOUR).toFixed(2);
  
    // Calculate recommended sets
    const calculateSets = () => {
      if (totalHours <= MAX_HOURS_PER_SET) {
        return 1;
      }
      return Math.ceil(totalHours / MAX_HOURS_PER_SET);
    };
  
    const recommendedSets = calculateSets();
    const filesPerSet = Math.ceil(totalFiles / recommendedSets);
    const hoursPerSet = ((filesPerSet * SECONDS_PER_FILE) / SECONDS_PER_HOUR).toFixed(2);
  
    return React.createElement('div', { className: 'runtime-calculator' },
      React.createElement('div', null,
        React.createElement('label', null, 'Number of Soil Samples'),
        React.createElement('input', {
          type: 'number',
          min: '0',
          value: soilSamples,
          onChange: (e) => setSoilSamples(parseInt(e.target.value) || ''),
          placeholder: 'Enter number of soil samples'
        })
      ),
      React.createElement('div', null,
        React.createElement('label', null, 'Number of Weather Files'),
        React.createElement('input', {
          type: 'number',
          min: '0',
          value: weatherFiles,
          onChange: (e) => setWeatherFiles(parseInt(e.target.value) || ''),
          placeholder: 'Enter number of weather files'
        })
      ),
      totalFiles > 0 && React.createElement('div', { className: 'results' },
        React.createElement('p', null, `Total number of files: ${totalFiles.toLocaleString()}`),
        React.createElement('p', null, `Processing time per file: ~${SECONDS_PER_FILE} seconds`),
        React.createElement('p', null, `Total runtime: ${totalHours} hours`)
      ),
      totalFiles > 0 && React.createElement('div', { 
        className: `alert ${recommendedSets > 1 ? 'alert-warning' : 'alert-success'}`
      },
        React.createElement('h4', null, 'Processing Recommendation'),
        recommendedSets === 1 
          ? React.createElement('p', null, 'All files can be processed in a single set (under 24 hours)')
          : React.createElement('div', null,
              React.createElement('p', null, `Recommended to split config.txt files into ${recommendedSets} sets:`),
              React.createElement('ul', null,
                React.createElement('li', null, `Files per set: ${filesPerSet.toLocaleString()}`),
                React.createElement('li', null, `Runtime per set: ${hoursPerSet} hours`)
              )
            )
      )
    );
  };