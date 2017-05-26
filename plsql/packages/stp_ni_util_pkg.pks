create or replace package stp_ni_util_pkg as 
  
  /* Pacakge for nursery inspection. */

  function validate_data_range return boolean;
  
  procedure create_or_save_tags;

  procedure group_action_on_tags (p_request in varchar2);

end stp_ni_util_pkg;