create or replace package body             stp_util_pkg as

  /************************************************************************************************
  /*
  /* @procedure: load_comment_collection
  /*
  /* @description: truncate the collection and load comments data into collection with
  /*               name COMMENT_COLLECTION_NAME.
  /*
  /* @type P_ITEM_ID In Number - the item id of the comments belong to.
  /************************************************************************************************/ 
  PROCEDURE load_comment_collection( P_ITEM_ID IN NUMBER)
  AS
  BEGIN

    
    APEX_COLLECTION.CREATE_OR_TRUNCATE_COLLECTION (COMMENT_COLLECTION_NAME);
    
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
  

  /************************************************************************************************
  /*
  /* @procedure: process_comment_collection
  /*
  /* @description: Load the comments data from collection back into table.
  /*
  /* @type P_ITEM_ID In Number - the item id of the comments belong to.
  /************************************************************************************************/ 
  PROCEDURE process_comment_collection( P_ITEM_ID IN NUMBER)
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


  /************************************************************************************************
  /*
  /* @function: load_parameter
  /*
  /* @description: map the numeric id back to the value in the given domain type.
  /*
  /* @type P_TYPE In Number - dpmain type.
  /* @type P_ID   In Number - numeric id in domain.
  /*
  /* @rtype Varchar2 - domain value based on domain type and numeric id.
  /************************************************************************************************/ 
  FUNCTION load_parameter( P_TYPE IN NUMBER,
                           P_ID   IN NUMBER) RETURN VARCHAR2
AS
    l_result varchar2(128);
  BEGIN
    
    
    CASE P_TYPE
    WHEN STP_CONSTANT_PKG.GC_T_ACTIVITY_TYPE    THEN  SELECT ACTIVITY INTO l_result FROM bsmart_data.STP_ACTIVITIES WHERE id = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_STOCK_TYPE       THEN  SELECT CODE_NAME INTO l_result FROM bsmart_data.stp_stocktype_lk WHERE CODE_VALUE = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_PLANT_TYPE       THEN  SELECT CODE_NAME INTO l_result FROM bsmart_data.stp_plantsize_lk WHERE CODE_VALUE = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_SPECIES          THEN  SELECT SPECIES INTO l_result FROM bsmart_data.STP_SPECIES_LK WHERE SPECIESID = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_STUMP_SIZE       THEN  SELECT CODE_NAME INTO l_result FROM bsmart_data.stp_stumping_lk WHERE CODE_VALUE = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_TRANSP_DIS       THEN  SELECT CODE_NAME INTO l_result FROM bsmart_data.stp_plantsize_lk WHERE CODE_VALUE = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_MARK_TYPE        THEN  SELECT MARK_TYPE  INTO l_result FROM bsmart_data.stp_mark_type WHERE id = P_ID;
    WHEN STP_CONSTANT_PKG.GC_T_MARKING_LOCATION THEN  SELECT MARKING_LOCATION INTO l_result FROM bsmart_data.stp_marking_location WHERE id = P_ID;
    END CASE; 
    
    
    RETURN l_result;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    RETURN NULL;
  END;
  
  
  /************************************************************************************************
  /*
  /* @function: get_domain_json
  /*
  /* @description: Get the domain json object from eTrans tables.
  /*
  /* @type P_LAYERID In Number - layer ID defined in eTrans Restful API.
  /*
  /* @rtype Varchar2 - domain json object.
  /*
  /* @note: In case of the API stop working, contact Bryan Bingham <Bryan.Bingham@york.ca>.
  /************************************************************************************************/   
  FUNCTION get_domain_json (P_LAYERID IN NUMBER) RETURN VARCHAR2
  AS
    l_http_request    UTL_HTTP.req;
    l_http_response   UTL_HTTP.resp;
    l_response_text   VARCHAR2 (32000);
    BEGIN
    -- preparing request
    l_http_request :=
      UTL_HTTP.begin_request (REPLACE(ETRANS_RESTFUL_URL, '%LAYER_ID%', TO_CHAR(P_LAYERID)),
                              'GET',
                              'HTTP/1.1');
    
    l_http_response := UTL_HTTP.get_response (l_http_request);
    
    UTL_HTTP.read_text (l_http_response, l_response_text);
    
    UTL_HTTP.end_response (l_http_response);
    RETURN  l_response_text;
    
    EXCEPTION
    WHEN UTL_HTTP.end_of_body
    THEN
      UTL_HTTP.end_response (l_http_response);
      RETURN NULL;
   END;
   
   /**********************************************************************
   /*
   /* @function: get_aop_query
   /*
   /* @description: Gets the aop query based on a given id
   /*
   /* @type P_ID In number - The ID of the query
   /*
   /* @rtype clob - the returned query
   /**********************************************************************/ 
   FUNCTION get_aop_query(P_ID IN NUMBER) RETURN VARCHAR2
   AS
    l_return clob;
    l_cont number := 0;
   BEGIN
   sys.dbms_output.enable;
    select aop.QUERY into l_return from STP_AOP_FACTORY aop where aop.ID = P_ID;
  
    return l_return;
   END;
   
   
  /************************************************************************************************
  /*
  /* @procedure: update_mv
  /*
  /* @description: Procedure for scheduled job to update materialzied domain lookup tables. 
  /************************************************************************************************/ 
   PROCEDURE UPDATE_MV
   AS
   BEGIN
    DBMS_MVIEW.REFRESH('BSMART_DATA.STP_TAGCOLOR_LK');
    DBMS_MVIEW.REFRESH('BSMART_DATA.STP_STOCKTYPE_LK');
    DBMS_MVIEW.REFRESH('BSMART_DATA.STP_SPECIES_LK');
    DBMS_MVIEW.REFRESH('BSMART_DATA.STP_TREEHEALTH_LK');
    DBMS_MVIEW.REFRESH('BSMART_DATA.STP_TREEHEIGHT_LK');
    DBMS_MVIEW.REFRESH('BSMART_DATA.STP_CONTRACTOPERATION_LK');
    DBMS_MVIEW.REFRESH('BSMART_DATA.STP_DEFICIENCY_STATUS_LK');
    DBMS_MVIEW.REFRESH('BSMART_DATA.STP_PLANTSIZE_LK');
    DBMS_MVIEW.REFRESH('BSMART_DATA.STP_WARRANTYINSPECTIONTYPE_LK');
    DBMS_MVIEW.REFRESH('BSMART_DATA.STP_STUMPING_LK');
   END;
   
end stp_util_pkg;