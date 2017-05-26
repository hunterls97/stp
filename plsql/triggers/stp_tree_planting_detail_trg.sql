create or replace TRIGGER BSMART_DATA.STP_TREE_PLANTING_DETAIL_TRG 
BEFORE INSERT OR UPDATE ON BSMART_DATA.STP_TREE_PLANTING_DETAIL
FOR EACH ROW
DECLARE
 l_CONTRACT_ITEM_NUM VARCHAR2(500);
 l_COUNT NUMBER;
BEGIN
  IF INSERTING THEN
    if(:NEW.ID is null) then
      SELECT BSMART_DATA.STP_ROW_ITEM_SEQ.NEXTVAL INTO :NEW.ID FROM DUAL;
    END IF;
    :NEW.CREATED_ON := SYSDATE;
    :NEW.CREATED_BY := NVL(V('APP_USER'),USER);
    /* Default Fields. */
    :NEW.STATUS_ID := 4;
    
    /* Set Item Num. */
    SELECT CONTRACT_ITEM_NUM into l_CONTRACT_ITEM_NUM from stp_contract_item where id=:NEW.CONTRACT_ITEM_ID;
    SELECT COUNT(*) into l_COUNT FROM STP_TREE_PLANTING_DETAIL WHERE CONTRACT_ITEM_ID = :NEW.CONTRACT_ITEM_ID;
    
    :NEW.DETAIL_NUM := l_CONTRACT_ITEM_NUM || ' - ' || CHR(65 + l_count);
    
    
  ELSIF UPDATING THEN
    :NEW.MODIFIED_ON := SYSDATE;
    :NEW.MODIFIED_BY := NVL(V('APP_USER'),USER);
    
    IF (:OLD.inspection_status is null or :OLD.inspection_status = 'Not Started') and
       (:NEW.inspection_status <> 'Not Started') THEN

       stp_pt_util_pkg.email_notification(  :NEW.id,
                                            :NEW.detail_num,
                                            :NEW.assignment_num,
                                            :NEW.planting_status,
                                            :NEW.start_date,
                                            :NEW.end_date,
                                            :NEW.inspector,
                                            :NEW.inspection_status,
                                            :NEW.contract_item_id,
                                            :NEW.status_id);

    END IF;
    
  END IF;
END;
