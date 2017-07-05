create or replace package                         STP_WARRANTY_PKG as
    
    function AOP_municipality_report 
    return varchar2;  
    
    function AOP_health_report
    return varchar2;
    
    function AOP_contract_report
    return varchar2;
  
end STP_WARRANTY_PKG;