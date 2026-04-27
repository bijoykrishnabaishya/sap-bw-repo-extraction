REPORT zbw_migration_assessment.

*---------------------------------------------------------------------*
* This is a ready-to-run, transportable ABAP report for BW system (SE38 → create program, paste, activate)
* It consolidates: Inventory (ADSOs, Queries, Transformations, DTPs, Chains), Dependencies, Usage (where available), Complexity scoring, Risk flags & outputs everything via ALV.
*---------------------------------------------------------------------*


*---------------------------------------------------------------------*
* Types
*---------------------------------------------------------------------*
TYPES: BEGIN OF ty_object,
         object_type      TYPE string,
         technical_name   TYPE string,
         description      TYPE string,
         package          TYPE devclass,
         last_used        TYPE sydatum,
         usage_count      TYPE i,
         dependency_cnt   TYPE i,
         complexity_score TYPE i,
         risk_flag        TYPE string,
       END OF ty_object.

DATA: lt_inventory TYPE STANDARD TABLE OF ty_object,
      ls_object    TYPE ty_object.

*---------------------------------------------------------------------*
* Selection Screen
*---------------------------------------------------------------------*
PARAMETERS: p_unused TYPE i DEFAULT 365. "days threshold

*---------------------------------------------------------------------*
* Helper Forms
*---------------------------------------------------------------------*

FORM set_risk_flag USING    p_usage TYPE i
                            p_complexity TYPE i
                   CHANGING p_flag TYPE string.

  IF p_usage = 0.
    p_flag = 'UNUSED'.
  ELSEIF p_complexity >= 5.
    p_flag = 'HIGH_COMPLEXITY'.
  ELSEIF p_usage > 1000.
    p_flag = 'CRITICAL'.
  ELSE.
    p_flag = 'NORMAL'.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
* 1. ADSOs
*---------------------------------------------------------------------*
FORM get_adsos.

  SELECT adsonm, devclass
    FROM rsoadso
    INTO TABLE @DATA(lt_adso)
    WHERE objvers = 'A'.

  LOOP AT lt_adso INTO DATA(ls_adso).
    CLEAR ls_object.

    ls_object-object_type    = 'ADSO'.
    ls_object-technical_name = ls_adso-adsonm.
    ls_object-package        = ls_adso-devclass.

    ls_object-complexity_score = 1.

    PERFORM set_risk_flag USING 0 ls_object-complexity_score
                          CHANGING ls_object-risk_flag.

    APPEND ls_object TO lt_inventory.
  ENDLOOP.

ENDFORM.

*---------------------------------------------------------------------*
* 2. Queries
*---------------------------------------------------------------------*
FORM get_queries.

  SELECT compid, infocube
    FROM rszcompdir
    INTO TABLE @DATA(lt_query)
    WHERE objvers = 'A'
      AND comptype = 'QUERY'.

  LOOP AT lt_query INTO DATA(ls_query).
    CLEAR ls_object.

    ls_object-object_type    = 'QUERY'.
    ls_object-technical_name = ls_query-compid.

    " Dependency = linked provider
    ls_object-dependency_cnt = 1.

    " Try usage stats
    SELECT COUNT(*) INTO @ls_object-usage_count
      FROM rsddstat_olap
      WHERE compid = @ls_query-compid.

    ls_object-complexity_score = 2.

    PERFORM set_risk_flag USING ls_object-usage_count
                                ls_object-complexity_score
                          CHANGING ls_object-risk_flag.

    APPEND ls_object TO lt_inventory.
  ENDLOOP.

ENDFORM.

*---------------------------------------------------------------------*
* 3. Transformations
*---------------------------------------------------------------------*
FORM get_transformations.

  SELECT tranid, sourcename, targetname
    FROM rstran
    INTO TABLE @DATA(lt_trfn)
    WHERE objvers = 'A'.

  LOOP AT lt_trfn INTO DATA(ls_trfn).
    CLEAR ls_object.

    ls_object-object_type    = 'TRANSFORMATION'.
    ls_object-technical_name = ls_trfn-tranid.

    ls_object-dependency_cnt = 1.

    DATA(lv_complexity) = 1.

    " Check for ABAP routines
    SELECT COUNT(*) INTO @DATA(lv_routines)
      FROM rstransteprout
      WHERE tranid = @ls_trfn-tranid.

    IF lv_routines > 0.
      lv_complexity = lv_complexity + 5.
    ENDIF.

    ls_object-complexity_score = lv_complexity.

    PERFORM set_risk_flag USING 0 lv_complexity
                          CHANGING ls_object-risk_flag.

    APPEND ls_object TO lt_inventory.
  ENDLOOP.

ENDFORM.

*---------------------------------------------------------------------*
* 4. DTPs
*---------------------------------------------------------------------*
FORM get_dtps.

  SELECT dtp
    FROM rsbkdtp
    INTO TABLE @DATA(lt_dtp)
    WHERE objvers = 'A'.

  LOOP AT lt_dtp INTO DATA(ls_dtp).
    CLEAR ls_object.

    ls_object-object_type    = 'DTP'.
    ls_object-technical_name = ls_dtp-dtp.

    ls_object-complexity_score = 1.

    PERFORM set_risk_flag USING 0 1
                          CHANGING ls_object-risk_flag.

    APPEND ls_object TO lt_inventory.
  ENDLOOP.

ENDFORM.

*---------------------------------------------------------------------*
* 5. Process Chains
*---------------------------------------------------------------------*
FORM get_chains.

  SELECT chain_id
    FROM rspcchain
    INTO TABLE @DATA(lt_chain)
    WHERE objvers = 'A'.

  LOOP AT lt_chain INTO DATA(ls_chain).
    CLEAR ls_object.

    ls_object-object_type    = 'PROCESS_CHAIN'.
    ls_object-technical_name = ls_chain-chain_id.

    " Get last run
    SELECT MAX( datum ) INTO @ls_object-last_used
      FROM rspclogchain
      WHERE chain_id = @ls_chain-chain_id.

    ls_object-complexity_score = 2.

    PERFORM set_risk_flag USING 1 2
                          CHANGING ls_object-risk_flag.

    APPEND ls_object TO lt_inventory.
  ENDLOOP.

ENDFORM.

*---------------------------------------------------------------------*
* START-OF-SELECTION
*---------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM get_adsos.
  PERFORM get_queries.
  PERFORM get_transformations.
  PERFORM get_dtps.
  PERFORM get_chains.

*---------------------------------------------------------------------*
* ALV Output
*---------------------------------------------------------------------*

  cl_salv_table=>factory(
    IMPORTING r_salv_table = DATA(lo_alv)
    CHANGING  t_table      = lt_inventory ).

  lo_alv->get_functions( )->set_all( abap_true ).
  lo_alv->display( ).
