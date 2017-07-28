create or replace PACKAGE                                     STP_CP_UTIL_PKG AS 

  DETAIL_COLLECTION_NAME CONSTANT VARCHAR2(30) := 'CONTRACT_DETAIL_COLLECTION';
  
  PROCEDURE load_detail_row(p_contract_item_id IN BSMART_DATA.STP_CONTRACT_DETAIL.CONTRACT_ITEM_ID%TYPE);

  PROCEDURE create_or_save_detail_row;

  PROCEDURE process_detail_rows(p_contract_item_id IN BSMART_DATA.STP_CONTRACT_DETAIL.CONTRACT_ITEM_ID%TYPE);

END STP_CP_UTIL_PKG;