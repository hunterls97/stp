create or replace PACKAGE BODY             STP_WI_UTIL_PKG AS


  /************************************************************************************************
  /*
  /* @procedure: process_form
  /*
  /* @description: Handler for warranty inspection form.
  /*
  /* TODO: this function is depracated, and will be redesigned.
  /************************************************************************************************/ 
  procedure process_form (p_id in stp_wrnty_inspection.id%type,
                          p_contract_year in stp_wrnty_inspection.contract_year%type,
                          p_contract_item_num in stp_wrnty_inspection.contract_item_num%type,
                          p_warranty_type_id in stp_wrnty_inspection.warranty_type_id%type,
                          p_warranty_inspector in stp_wrnty_inspection.warranty_inspector%type,
                          p_warrant_inspection_status in stp_wrnty_inspection.warrant_inspection_status%type,
                          p_repl_status in stp_wrnty_inspection.replacement_status%type,
                          p_repl_inspectior in stp_wrnty_inspection.replancement_inspectior%type,
                          p_repl_inspection_status in stp_wrnty_inspection.replacement_inspection_status%type)
  AS
  BEGIN
  merge into stp_wrnty_inspection using dual on (p_id = id)
  when not matched then
  insert (CONTRACT_YEAR,
          CONTRACT_ITEM_NUM,
          WARRANTY_TYPE_ID,
          WARRANTY_INSPECTOR,
          WARRANT_INSPECTION_STATUS,
          REPLACEMENT_STATUS,
          REPLANCEMENT_INSPECTIOR,
          REPLACEMENT_INSPECTION_STATUS
          ) values (
              p_contract_year,
              p_contract_item_num,
              p_warranty_type_id,
              p_warranty_inspector,
              p_warrant_inspection_status,
              p_repl_status,
              p_repl_inspectior,
              p_repl_inspection_status
          )
  when matched then 
  update set
  WARRANTY_INSPECTOR = p_warranty_inspector,
  WARRANT_INSPECTION_STATUS = p_warrant_inspection_status,
  REPLACEMENT_STATUS = p_repl_status,
  REPLANCEMENT_INSPECTIOR = p_repl_inspectior,
  REPLACEMENT_INSPECTION_STATUS = p_repl_inspection_status;

  end;

  /* TODO: this function is depracated, and will be redesigned. */
  procedure email_notification (p_contract_item_num in stp_wrnty_inspection.contract_item_num%type,
                          p_warranty_inspector in stp_wrnty_inspection.warranty_inspector%type,
                          p_warrant_inspection_status in stp_wrnty_inspection.warrant_inspection_status%type,
                          p_repl_status in stp_wrnty_inspection.replacement_status%type,
                          p_repl_inspectior in stp_wrnty_inspection.replancement_inspectior%type,
                          p_repl_inspection_status in stp_wrnty_inspection.replacement_inspection_status%type)
  as
    l_template stp_email_template%rowtype;
  begin
    select * into l_template
    from stp_email_template where id = 3;
    
    -- Substitutions
    l_template.subject := REPLACE(l_template.subject, '##ContractItemNum##', p_contract_item_num);
    l_template.subject := REPLACE(l_template.subject, '##WarrantyInspector##', p_warranty_inspector);
    l_template.subject := REPLACE(l_template.subject, '##InspectStatus##', p_warrant_inspection_status);
    l_template.subject := REPLACE(l_template.subject, '##ReplaceStatus##', p_repl_status);
    l_template.subject := REPLACE(l_template.subject, '##ReplaceInspector##', p_repl_inspectior);
    l_template.subject := REPLACE(l_template.subject, '##ReplaceInspectionStatus##', p_repl_inspection_status);

    l_template.template := REPLACE(l_template.template, '##ContractItemNum##', p_contract_item_num);
    l_template.template := REPLACE(l_template.template, '##WarrantyInspector##', p_warranty_inspector);
    l_template.template := REPLACE(l_template.template, '##InspectStatus##', p_warrant_inspection_status);
    l_template.template := REPLACE(l_template.template, '##ReplaceStatus##', p_repl_status);
    l_template.template := REPLACE(l_template.template, '##ReplaceInspector##', p_repl_inspectior);
    l_template.template := REPLACE(l_template.template, '##ReplaceInspectionStatus##', p_repl_inspection_status);
    
    email_util_pkg.send_email(p_to => 'hunter.schofield@york.ca' ||';'|| 'gary.kang@york.ca',--org_util_pkg.get_emails(p_inspector)),
                              p_from_address => 'hunter.schofield@york.ca',
                              p_from_name => 'Street Tree Planting and Establishment Contract Administration System',
                              p_subject => l_template.subject,
                              p_message => l_template.template);
  end;
            
END STP_WI_UTIL_PKG;