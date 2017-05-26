create or replace PACKAGE                         STP_CONSTANT_PKG AS 

  /* Package for Contract Preparation. */

  GC_UPDATE_RATE_QUERY varchar2(1000) := 'UPDATE BSMART_DATA.STP_PRICE SP1 SET PRICE_EST=(SELECT SP2.UNIT_PRICE
                                              FROM BSMART_DATA.STP_PRICE SP2
                                              WHERE SP1.YEAR = SP2.YEAR + 1 AND
                                                   (SP2.type is null or SP1.TYPE = SP2.type) AND
                                                  (SP2.stock_type is null or SP1.STOCK_TYPE = SP2.stock_type) AND
                                                  (SP2.plant_type is null or SP1.PLANT_TYPE = SP2.plant_type) AND
                                                  (SP2.species is null or SP1.SPECIES = SP2.species) AND 
                                                  (SP2.stumping_size is null or SP1.STUMPING_SIZE = SP2.stumping_size) AND
                                                  (SP2.transp_dis is null or SP1.TRANSP_DIS = SP2.transp_dis))*{RATE} WHERE YEAR={YEAR}';
  
  /* ACTIVITY ENUM */
  GC_T_ACTIVITY_TYPE  CONSTANT NUMBER := 0;
  GC_T_STOCK_TYPE     CONSTANT NUMBER := 1;
  GC_T_PLANT_TYPE     CONSTANT NUMBER := 2;
  GC_T_SPECIES        CONSTANT NUMBER := 3;
  GC_T_STUMP_SIZE     CONSTANT NUMBER := 4;
  GC_T_TRANSP_DIS     CONSTANT NUMBER := 5;
  
  /* Email Related. */
  GC_EM_REPLY_ADDRESS CONSTANT BSMART_DATA.AUTH_USER.EMAIL%TYPE := 'apex.support@york.ca;';
  GC_EM_REPLY_NAME CONSTANT VARCHAR(100) := 'Street Tree Planting and Establishment Contract Administration System';
  
  
  GC_EM_LOCK_TITLE VARCHAR2(100) := '[Notification] Contract Items Have Been Locked';
  GC_EM_LOCK_HEADER VARCHAR2(300) := 'Notification from Street Tree Planting and Establishment Contract Administration System<br><br>
                                      The following items has been locked by the administrator: <br>';
  GC_EM_LOCK_ITEM   VARCHAR2(300) := ' <a href="http://ykr-dev-apex.devyork.ca/apexenv/f?p=199:3:::NO:13:P3_ID:{ITEM_ID}">{ITEM_NUM}</a>.<br>';

                                       
END STP_CONSTANT_PKG;