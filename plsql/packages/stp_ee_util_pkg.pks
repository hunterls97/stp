create or replace PACKAGE             STP_EE_UTIL_PKG AS 
  
  gc_extra_work_coll CONSTANT VARCHAR2(30) := 'EXTRA_WORK_COLL';
  gc_extra_work_detail_coll CONSTANT VARCHAR2(30) := 'EXTRA_WORK_DETAIL_COLL';
  
  
  procedure create_extra_work_coll(p_year in number);

END STP_EE_UTIL_PKG;