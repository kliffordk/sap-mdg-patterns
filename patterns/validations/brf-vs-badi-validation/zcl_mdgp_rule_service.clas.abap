"! <p>Thin BAdI shell for validations — SAP MDG Patterns, pattern 1.</p>
"! <p><strong>Illustrative — structure only, not executed.</strong></p>
"! <p>[VERIFY] in SE18 / SE19 for your release:</p>
"! <ul>
"!   <li>the rule service BAdI name (USMD_RULE_SERVICE) and its interface</li>
"!   <li>the exact method names and parameters for entity checks and messages</li>
"!   <li>the entity type name in your data model</li>
"! </ul>
"! <p>This class only connects the MDG framework to ZCL_MDGP_MATERIAL_VALIDATOR.
"! All rule logic lives in the validator, where it is unit tested.</p>
CLASS zcl_mdgp_rule_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " [VERIFY] interface name for BAdI USMD_RULE_SERVICE in your release.
    INTERFACES if_ex_usmd_rule_service.

  PRIVATE SECTION.
    " [VERIFY] entity type name in your data model.
    CONSTANTS c_entity_material TYPE string VALUE `MATERIAL`.

    "! Configuration is read once and kept for the rest of the change request,
    "! so mass processing does not hit the database for every record.
    DATA mt_types_needing_group TYPE zcl_mdgp_material_validator=>ty_mtart_range.
    DATA mv_config_loaded       TYPE abap_bool.

    METHODS get_validator
      RETURNING VALUE(ro_validator) TYPE REF TO zcl_mdgp_material_validator.

ENDCLASS.



CLASS zcl_mdgp_rule_service IMPLEMENTATION.

  " [VERIFY] Implement the entity-check method of the interface here.
  " Keep it to these five steps — no rule logic in this class:
  "
  "   1. If the entity type is not c_entity_material, RETURN.
  "   2. Map the entity data the framework hands in to
  "      zcl_mdgp_material_validator=>ty_materials (only the fields the rules need).
  "   3. DATA(lt_messages) = get_validator( )->validate( lt_materials ).
  "   4. Map each ty_message to the framework's message table:
  "        severity → message type, field → field reference, text → message
  "        (in a real system: message class + number, rule ID as a variable).
  "   5. Return.
  "
  " Add empty implementations for the remaining interface methods, with a short
  " comment saying they are intentionally unused.


  METHOD get_validator.
    IF mv_config_loaded = abap_false.
      " Illustrative customizing table ZMDGP_RULE_CFG (rule_id, mtart).
      " Business-owned values live here, not in the code.
      SELECT 'I' AS sign, 'EQ' AS option, mtart AS low
        FROM zmdgp_rule_cfg
        WHERE rule_id = 'MAT-001'
        INTO CORRESPONDING FIELDS OF TABLE @mt_types_needing_group.
      mv_config_loaded = abap_true.
    ENDIF.

    ro_validator = NEW #( mt_types_needing_group ).
  ENDMETHOD.

ENDCLASS.
