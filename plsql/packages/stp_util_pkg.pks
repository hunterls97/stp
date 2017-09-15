create or replace package             stp_util_pkg as 
  
  /************************************************************************
  /*
  /* @file_name: stp_util_pkg.pks
  /* @author: Gary Kang
  /*  
  /* @description: Common utility functions for STP applications
  /*
  *************************************************************************/ 

  -- Common comment collection name for all comment areas.
  COMMENT_COLLECTION_NAME CONSTANT VARCHAR2(30) := 'COMMENT_COLLECTION';
  -- eTrans RESTful API URL.
  ETRANS_RESTFUL_URL CONSTANT VARCHAR2(2048) := 'http://ykr-geo-cw4/arcgis/rest/services/Cityworks/CWForestry_etransprd/MapServer/%LAYER_ID%?f=json'
;
  PROCEDURE LOAD_COMMENT_COLLECTION( P_ITEM_ID IN NUMBER);
  
  PROCEDURE PROCESS_COMMENT_COLLECTION( P_ITEM_ID IN NUMBER);

  FUNCTION LOAD_PARAMETER( P_TYPE IN NUMBER,
                           P_ID   IN NUMBER) RETURN VARCHAR2;
  
  FUNCTION GET_DOMAIN_JSON( P_LAYERID IN NUMBER) RETURN VARCHAR2;
  
  FUNCTION GET_AOP_QUERY(P_ID IN NUMBER)
  RETURN VARCHAR2;
  
  PROCEDURE UPDATE_MV;
                           


end stp_util_pkg;