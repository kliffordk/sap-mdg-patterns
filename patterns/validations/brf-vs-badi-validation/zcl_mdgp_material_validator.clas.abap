"! <p>Validation rules for the MATERIAL entity — SAP MDG Patterns, pattern 1.</p>
"! <p><strong>Illustrative — not executed.</strong> Written from scratch for the pattern library.</p>
"! <p>Plain ABAP with no dependency on the MDG framework, so every rule can be
"! covered by ABAP Unit tests and reused outside the BAdI (mass changes, migration checks).</p>
"! <p>Conventions: one method per rule, named after the rule; rule ID in every message.</p>
CLASS zcl_mdgp_material_validator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      "! The fields the rules need — not the whole entity.
      BEGIN OF ty_material,
        matnr TYPE matnr,
        mtart TYPE mtart,
        matkl TYPE matkl,
        bismt TYPE bismt,
      END OF ty_material,
      ty_materials TYPE STANDARD TABLE OF ty_material WITH EMPTY KEY,

      "! Material types that require a material group (rule MAT-001).
      ty_mtart_range TYPE RANGE OF mtart,

      "! Framework-neutral message; the BAdI shell maps it to the MDG message table.
      BEGIN OF ty_message,
        matnr    TYPE matnr,
        rule_id  TYPE string,
        severity TYPE symsgty,
        field    TYPE fieldname,
        text     TYPE string,
      END OF ty_message,
      ty_messages TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY.

    CONSTANTS:
      c_trading_goods TYPE mtart VALUE 'HAWA'.

    "! @parameter it_types_needing_group | Configuration for MAT-001, read by the caller
    "!                                     (e.g. from a customizing table). Never hard-coded here.
    METHODS constructor
      IMPORTING it_types_needing_group TYPE ty_mtart_range.

    "! Runs every rule against every material.
    METHODS validate
      IMPORTING it_materials       TYPE ty_materials
      RETURNING VALUE(rt_messages) TYPE ty_messages.

  PRIVATE SECTION.
    DATA mt_types_needing_group TYPE ty_mtart_range.

    "! MAT-001 (error): configured material types must have a material group.
    METHODS rule_mat001_group_required
      IMPORTING is_material        TYPE ty_material
      RETURNING VALUE(rt_messages) TYPE ty_messages.

    "! MAT-002 (warning): trading goods should carry an old material number.
    METHODS rule_mat002_trading_old_number
      IMPORTING is_material        TYPE ty_material
      RETURNING VALUE(rt_messages) TYPE ty_messages.

ENDCLASS.



CLASS zcl_mdgp_material_validator IMPLEMENTATION.

  METHOD constructor.
    mt_types_needing_group = it_types_needing_group.
  ENDMETHOD.


  METHOD validate.
    " No database access in here: everything the rules need is passed in.
    " That keeps the loop fast for mass processing.
    LOOP AT it_materials INTO DATA(ls_material).
      APPEND LINES OF rule_mat001_group_required( ls_material ) TO rt_messages.
      APPEND LINES OF rule_mat002_trading_old_number( ls_material ) TO rt_messages.
    ENDLOOP.
  ENDMETHOD.


  METHOD rule_mat001_group_required.
    " Guard against an empty range: "value IN empty_range" is TRUE in ABAP,
    " so missing configuration would otherwise apply this rule to every material type.
    IF mt_types_needing_group IS INITIAL.
      RETURN.
    ENDIF.

    IF is_material-mtart IN mt_types_needing_group
       AND is_material-matkl IS INITIAL.
      " In a real system, use a message class so the text can be translated.
      rt_messages = VALUE #( (
        matnr    = is_material-matnr
        rule_id  = `MAT-001`
        severity = 'E'
        field    = 'MATKL'
        text     = |MAT-001: Material group is required for material type { is_material-mtart }.| ) ).
    ENDIF.
  ENDMETHOD.


  METHOD rule_mat002_trading_old_number.
    IF is_material-mtart = c_trading_goods
       AND is_material-bismt IS INITIAL.
      rt_messages = VALUE #( (
        matnr    = is_material-matnr
        rule_id  = `MAT-002`
        severity = 'W'
        field    = 'BISMT'
        text     = |MAT-002: Trading goods should have an old material number for traceability.| ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
