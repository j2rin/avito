SELECT
    event_date                        
    ,report_datetime                   
    ,event_timestamp                   
    ,user_id                           
    ,platform_id                       
    ,auth_source                       
    ,is_hacked                         
    ,is_moderation_hack                
    ,is_fraudster_by_hack              
    ,is_hack_auth_susp                 
    ,is_hack_auth_not_susp             
    ,is_hack_restore_phone_susp        
    ,is_hack_restore_phone_not_susp    
    ,is_hack_direct_auth_susp          
    ,is_hack_direct_auth_not_susp      
    ,is_hack_restore_email_susp        
    ,is_hack_restore_email_not_susp    
    ,susp_auth_attempts                
    ,not_susp_auth_attempts            
    ,susp_auth_attempts_with_check     
    ,not_susp_auth_attempts_with_sheck 
    ,susp_auth_success                 
    ,not_susp_auth_success             
    ,susp_auth_success_with_check      
    ,not_susp_auth_success_with_check 
FROM dma.hacked_metrics 
WHERE event_date BETWEEN :first_date AND :last_date
