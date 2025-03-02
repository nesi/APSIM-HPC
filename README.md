how to use it:

Save the script as snakemake_monitor.py
Make it executable: chmod +x snakemake_monitor.py
Run it:

To monitor all jobs: ./snakemake_monitor.py
To monitor a specific workflow: ./snakemake_monitor.py --workflow-id YOUR_WORKFLOW_ID
To change refresh rate: ./snakemake_monitor.py --refresh-rate 10



Features:

Live-updating dashboard using curses
Job statistics showing counts by state (RUNNING, COMPLETED, FAILED, etc.)
Detailed view of active jobs including:

Job ID and name
Current state
Elapsed time
Memory usage
CPU allocation


Press 'q' to quit
