create or replace PACKAGE                                                             STP_CONSTANT_PKG AS 

  /* ACTIVITY ENUM */
  GC_T_ACTIVITY_TYPE    CONSTANT NUMBER := 0;
  GC_T_STOCK_TYPE       CONSTANT NUMBER := 1;
  GC_T_PLANT_TYPE       CONSTANT NUMBER := 2;
  GC_T_SPECIES          CONSTANT NUMBER := 3;
  GC_T_STUMP_SIZE       CONSTANT NUMBER := 4;
  GC_T_TRANSP_DIS       CONSTANT NUMBER := 5;
  GC_T_MARK_TYPE        CONSTANT NUMBER := 6;
  GC_T_MARKING_LOCATION CONSTANT NUMBER := 7;
  /* Email Related. */
  GC_EM_REPLY_ADDRESS CONSTANT BSMART_DATA.AUTH_USER.EMAIL%TYPE := 'apex.support@york.ca;';
  GC_EM_REPLY_NAME CONSTANT VARCHAR(100) := 'Street Tree Planting and Establishment Contract Administration System';
  
  
  GC_EM_LOCK_TITLE VARCHAR2(100) := '[Notification] Contract Items Have Been Locked';
  GC_EM_LOCK_HEADER VARCHAR2(300) := 'Notification from Street Tree Planting and Establishment Contract Administration System<br><br>
                                      The following items has been locked by the administrator: <br>';
  GC_EM_LOCK_ITEM   VARCHAR2(300) := ' <a href="http://ykr-dev-apex.devyork.ca/apexenv/f?p=199:3:::NO:13:P3_ID:{ITEM_ID}">{ITEM_NUM}</a>.<br>';

                                       
END STP_CONSTANT_PKG;