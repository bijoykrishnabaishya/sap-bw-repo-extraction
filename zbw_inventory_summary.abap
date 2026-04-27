REPORT zbw_inventory_summary.

*---------------------------------------------------------------------*
* ABAP Consolidated Inventory Report:: zbw_inventory_summary
*---------------------------------------------------------------------*


TYPES: BEGIN OF ty_summary,
         object_type TYPE string,
         count       TYPE i,
       END OF ty_summary.

DATA: lt_summary TYPE STANDARD TABLE OF ty_summary,
      ls_summary TYPE ty_summary.

*---------------------------------------------------------------------*
* InfoProviders
*---------------------------------------------------------------------*

" ADSOs
SELECT COUNT(*) INTO @DATA(lv_adso)
  FROM rsoadso
  WHERE objvers = 'A'.

ls_summary-object_type = 'ADSOs'.
ls_summary-count = lv_adso.
APPEND ls_summary TO lt_summary.

" InfoCubes
SELECT COUNT(*) INTO @DATA(lv_cube)
  FROM rsdcube
  WHERE objvers = 'A'.

ls_summary-object_type = 'InfoCubes'.
ls_summary-count = lv_cube.
APPEND ls_summary TO lt_summary.

" Classic DSOs
SELECT COUNT(*) INTO @DATA(lv_dso)
  FROM rsdodso
  WHERE objvers = 'A'.

ls_summary-object_type = 'Classic DSOs'.
ls_summary-count = lv_dso.
APPEND ls_summary TO lt_summary.

*---------------------------------------------------------------------*
* BW Queries
*---------------------------------------------------------------------*

SELECT COUNT(*) INTO @DATA(lv_query)
  FROM rszcompdir
  WHERE objvers = 'A'
    AND comptype = 'QUERY'.

ls_summary-object_type = 'BW Queries'.
ls_summary-count = lv_query.
APPEND ls_summary TO lt_summary.

*---------------------------------------------------------------------*
* Transformations
*---------------------------------------------------------------------*

SELECT COUNT(*) INTO @DATA(lv_trfn)
  FROM rstran
  WHERE objvers = 'A'.

ls_summary-object_type = 'Transformations'.
ls_summary-count = lv_trfn.
APPEND ls_summary TO lt_summary.

*---------------------------------------------------------------------*
* DTPs
*---------------------------------------------------------------------*

SELECT COUNT(*) INTO @DATA(lv_dtp)
  FROM rsbkdtp
  WHERE objvers = 'A'.

ls_summary-object_type = 'DTPs'.
ls_summary-count = lv_dtp.
APPEND ls_summary TO lt_summary.

*---------------------------------------------------------------------*
* Process Chains
*---------------------------------------------------------------------*

SELECT COUNT(*) INTO @DATA(lv_chain)
  FROM rspcchain
  WHERE objvers = 'A'.

ls_summary-object_type = 'Process Chains'.
ls_summary-count = lv_chain.
APPEND ls_summary TO lt_summary.

*---------------------------------------------------------------------*
* Output (ALV)
*---------------------------------------------------------------------*

cl_salv_table=>factory(
  IMPORTING r_salv_table = DATA(lo_alv)
  CHANGING  t_table      = lt_summary ).

lo_alv->display( ).
