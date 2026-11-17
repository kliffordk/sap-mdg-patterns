"! ABAP Unit tests for ZCL_MDGP_MATERIAL_VALIDATOR — SAP MDG Patterns, pattern 1.
"! Illustrative — not executed. Each test covers one scenario from the pattern's testing table.
CLASS ltc_material_validator DEFINITION FINAL
  FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      listed_type_without_group   FOR TESTING,
      listed_type_with_group      FOR TESTING,
      unlisted_type_without_group FOR TESTING,
      empty_config_skips_mat001   FOR TESTING,
      trading_good_without_old_no FOR TESTING,
      trading_good_with_old_no    FOR TESTING.

    "! Configuration used by most tests: only FERT requires a material group.
    METHODS fert_only
      RETURNING VALUE(rt_range) TYPE zcl_mdgp_material_validator=>ty_mtart_range.

    METHODS validate
      IMPORTING it_types           TYPE zcl_mdgp_material_validator=>ty_mtart_range
                is_material        TYPE zcl_mdgp_material_validator=>ty_material
      RETURNING VALUE(rt_messages) TYPE zcl_mdgp_material_validator=>ty_messages.

ENDCLASS.



CLASS ltc_material_validator IMPLEMENTATION.

  METHOD fert_only.
    rt_range = VALUE #( ( sign = 'I' option = 'EQ' low = 'FERT' ) ).
  ENDMETHOD.


  METHOD validate.
    rt_messages = NEW zcl_mdgp_material_validator( it_types )->validate( VALUE #( ( is_material ) ) ).
  ENDMETHOD.


  METHOD listed_type_without_group.
    DATA(lt_messages) = validate(
      it_types    = fert_only( )
      is_material = VALUE #( matnr = 'TEST-001' mtart = 'FERT' ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_messages ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_messages[ 1 ]-rule_id  exp = `MAT-001` ).
    cl_abap_unit_assert=>assert_equals( act = lt_messages[ 1 ]-severity exp = 'E' ).
    cl_abap_unit_assert=>assert_equals( act = lt_messages[ 1 ]-field    exp = 'MATKL' ).
  ENDMETHOD.


  METHOD listed_type_with_group.
    DATA(lt_messages) = validate(
      it_types    = fert_only( )
      is_material = VALUE #( matnr = 'TEST-002' mtart = 'FERT' matkl = '01' ) ).

    cl_abap_unit_assert=>assert_initial( lt_messages ).
  ENDMETHOD.


  METHOD unlisted_type_without_group.
    DATA(lt_messages) = validate(
      it_types    = fert_only( )
      is_material = VALUE #( matnr = 'TEST-003' mtart = 'ROH' ) ).

    cl_abap_unit_assert=>assert_initial( lt_messages ).
  ENDMETHOD.


  METHOD empty_config_skips_mat001.
    " Protects against the empty-range pitfall: no configuration must mean "rule off",
    " not "rule applies to every material type".
    DATA(lt_messages) = validate(
      it_types    = VALUE #( )
      is_material = VALUE #( matnr = 'TEST-004' mtart = 'FERT' ) ).

    cl_abap_unit_assert=>assert_initial( lt_messages ).
  ENDMETHOD.


  METHOD trading_good_without_old_no.
    DATA(lt_messages) = validate(
      it_types    = fert_only( )
      is_material = VALUE #( matnr = 'TEST-005' mtart = 'HAWA' matkl = '01' ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_messages ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_messages[ 1 ]-rule_id  exp = `MAT-002` ).
    cl_abap_unit_assert=>assert_equals( act = lt_messages[ 1 ]-severity exp = 'W' ).
  ENDMETHOD.


  METHOD trading_good_with_old_no.
    DATA(lt_messages) = validate(
      it_types    = fert_only( )
      is_material = VALUE #( matnr = 'TEST-006' mtart = 'HAWA' matkl = '01' bismt = 'LEGACY-123' ) ).

    cl_abap_unit_assert=>assert_initial( lt_messages ).
  ENDMETHOD.

ENDCLASS.
