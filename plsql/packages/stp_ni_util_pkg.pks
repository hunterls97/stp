create or replace package             stp_ni_util_pkg as 
  
  /************************************************************************************************
  /*
  /* @file_name: stp_ni_util_pkg.pks
  /* @author: Gary Kang
  /*  
  /* @description: Common utility functions for STP application - Nursery Inspection.
  /*
  /************************************************************************************************/ 


  function validate_data_range return boolean;
  
  procedure create_or_save_tags;

  procedure group_action_on_tags (p_request in varchar2);

end stp_ni_util_pkg;