create or replace package body             stp_util_pkg as

    FUNCTION GET_CONTRACT_NUM(P_YEAR IN NUMBER) RETURN VARCHAR2
    AS
      l_result varchar2(100);
    BEGIN
      SELECT CONTRACTNUMBER INTO l_result 
      FROM "TRANSD"."FSTCONTRACTNUMBER"@ETRANS.YKREGION.CA FCN
      where SUBSTR(FCN.CONTRACTNUMBER, 3, 2) = P_YEAR - 2000;
      
      RETURN l_result;

    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END; 
 
    

    /* ---------------- < Get Watering amount > ---------------- */
    FUNCTION GET_WATERING_AMOUNT( p_year   IN NUMBER )RETURN number
    IS
      l_number NUMBER;
    BEGIN
    /*
      select NVL(SUM(QUANTITY),0) INTO l_number from bsmart_Data.stp_items_v where year=p_year and type = 'Tree Planting';
      return l_number*14;
      */
      return 0;
    END;
 

  /* Send Locking Notification */
  PROCEDURE send_lock_notification( p_year IN NUMBER, p_comments IN VARCHAR2 DEFAULT NULL)
  AS
    cursor c_creator is
    SELECT DISTINCT CREATED_BY AS creator FROM stp_contract_item WHERE YEAR = p_year;

    cursor c_items (p_creator VARCHAR2 ) is
    select ID, contract_item_num
    from stp_contract_item
    where CREATED_BY = p_creator and STATUS_ID = 2;

    l_template varchar2(300);
    l_body clob;
  BEGIN
    for rec in c_creator
    
    LOOP
      l_body :=  STP_CONSTANT_PKG.GC_EM_LOCK_HEADER;

      IF p_comments IS NOT NULL THEN
        l_body := l_body || '<b>Comments:</b><br>' || p_comments || '<br>';
      END IF; 

      for item in c_items (rec.creator) 
      LOOP
        l_template := STP_CONSTANT_PKG.GC_EM_LOCK_ITEM;
        l_template :=  REPLACE(l_template, '{ITEM_ID}', TO_CHAR(item.id));
        l_template :=  REPLACE(l_template, '{ITEM_NUM}', TO_CHAR(item.contract_item_num));
        l_body := l_body || l_template;
      END LOOP;

      EMAIL_UTIL_PKG.send_email(ORG_UTIL_PKG.GET_EMAILS(rec.creator),
                          STP_CONSTANT_PKG.GC_EM_REPLY_ADDRESS,
                          STP_CONSTANT_PKG.GC_EM_REPLY_NAME,
                          STP_CONSTANT_PKG.GC_EM_LOCK_TITLE,
                          l_body);
    END LOOP; 
  END;
 
  PROCEDURE LOAD_COMMENT_COLLECTION( P_ITEM_ID IN NUMBER)
  AS
  BEGIN

    /* Truncate Comment Collection. */
    if APEX_COLLECTION.COLLECTION_EXISTS (COMMENT_COLLECTION_NAME) then
        APEX_COLLECTION.DELETE_COLLECTION (COMMENT_COLLECTION_NAME);
    end if;
    
    APEX_COLLECTION.CREATE_COLLECTION(COMMENT_COLLECTION_NAME);
    
    for rec in (SELECT
                C."ID" "ID",
                C.CREATED_ON "DATE",
                to_char(C.CREATED_ON, 'HH24:Mi') "TIME",
                E.FIRST_NAME || ' ' || E.LAST_NAME "USER",
                C.COMMENTS "COMMENT"
                FROM stp_comments C
                JOIN BSMART_DATA.AUTH_USER E
                ON E.USER_NAME = C.CREATED_BY
                WHERE C.ITEM_ID = P_ITEM_ID
                ORDER BY 1 DESC,2 DESC)
    loop
    
        APEX_COLLECTION.ADD_MEMBER(
             p_collection_name => COMMENT_COLLECTION_NAME
            ,p_c001 => rec."TIME"
            ,p_c002 => rec."USER"
            ,p_c003 => rec."COMMENT"
            ,p_d001 => rec."DATE"
            ,p_n001 => rec."ID"
        );
    end loop;
  END;
  
  PROCEDURE PROCESS_COMMENT_COLLECTION( P_ITEM_ID IN NUMBER)
  AS
    l_comment_id number;
  BEGIN

      for rec2 in(
        select c003, d001, seq_id
        from apex_collections
        where collection_name = COMMENT_COLLECTION_NAME
        and n001 is null
      )
      loop
        insert into BSMART_DATA.STP_COMMENTS(COMMENTS, ITEM_ID, CREATED_ON)
        values (rec2.c003, P_ITEM_ID, rec2.d001)
        returning ID into l_comment_id;
        
        apex_collection.update_member_attribute(p_collection_name => COMMENT_COLLECTION_NAME, p_seq => rec2.seq_id, p_attr_number => 1, p_number_value => l_comment_id);
      end loop;

  END;

  FUNCTION LOAD_PARAMETER( P_TYPE IN NUMBER,
                           P_ID   IN NUMBER) RETURN VARCHAR2
AS
    l_result varchar2(128);
  BEGIN

    CASE P_TYPE
    WHEN STP_CONSTANT_PKG.GC_T_ACTIVITY_TYPE    THEN  SELECT ACTIVITY INTO l_result FROM bsmart_data.STP_ACTIVITIES WHERE id = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_STOCK_TYPE       THEN  SELECT TYPE_NAME INTO l_result FROM bsmart_data.stp_stock_type WHERE id = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_PLANT_TYPE       THEN  SELECT PLANT_TYPE INTO l_result FROM bsmart_data.stp_plant_type WHERE id = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_SPECIES          THEN  SELECT SPECIES INTO l_result FROM bsmart_data.stp_species WHERE id = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_STUMP_SIZE       THEN  SELECT STUMP_SIZE INTO l_result FROM bsmart_data.stp_stump_size WHERE id = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_TRANSP_DIS       THEN  SELECT DISTANCE INTO l_result FROM bsmart_data.stp_transp_dis WHERE id = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_MARK_TYPE        THEN  SELECT MARK_TYPE  INTO l_result FROM bsmart_data.stp_mark_type WHERE id = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_MARKING_LOCATION THEN  SELECT MARKING_LOCATION INTO l_result FROM bsmart_data.stp_marking_location WHERE id = P_ID;
    END CASE;
    
    RETURN l_result;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    RETURN NULL;
  END;
  

end stp_util_pkg;