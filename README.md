# sap-bw-repo-extraction
SAP BW migration assessment extractors:

-------------------------------------------------------------------------------------------------------
1. zbw_inventory_summary
This is an ABAP REPORT that gives you:
    *Counts per object type
    *Optional breakdowns
    *Easy export (ALV → Excel)

-------------------------------------------------------------------------------------------------------
2. zbw_migration_assessment
This is a ready-to-run, transportable ABAP report for BW system (SE38 → create program, paste, activate)
Think in terms of 4 layers:
i. Inventory (what exists)
    *InfoProviders (ADSOs, Cubes, DSOs)
    *Queries
    *Transformations
    *DTPs
    *Process Chains
ii. Dependency mapping (how things connect)
    *Source → Transformation → Target
    *Target → Queries
    *Process Chains → DTPs
iii. Usage (what actually matters)
    *Last executed query
    *Frequency
    *Process Chains last run
iv. Complexity scoring (how hard to migrate)
    *Rule types in transformations
    *Number of joins/lookups
    *Custom code (ABAP routines)

-------------------------------------------------------------------------------------------------------
3. Consolidated BW Objects Inventory
For HANA-native extraction, create a calculation view or SQL script like this



