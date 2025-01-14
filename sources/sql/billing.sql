   select observation_date as event_date,
   		  platform_id,
   		  participant_id as user_id,
   		  payment_method_page,
    	  payment_method_choice,
    	  successful_payment,
    	  successful_payment_card,
    	  successful_payment_sbol,
    	  successful_payment_sms,
    	  payment_method_page_cv,
    	  payment_method_choice_cv,
    	  successful_payment_cv,
    	  payment_method_page_wallet,
    	  payment_method_choice_wallet,
    	  successful_payment_wallet,
    	  payment_method_page_services,
    	  payment_method_choice_services,
     	  successful_payment_services,
        wallet_amount,   
    	  services_amount,
        payment_method_page_subs,
        payment_method_choice_subs,
        successful_payment_subs,
        successful_payment - successful_payment_subs - successful_payment_cv - successful_payment_wallet as successful_payment_account_pay,
        payment_method_page - payment_method_page_subs - payment_method_page_cv - payment_method_page_wallet as payment_method_page_account_pay,
        payment_method_choice - payment_method_choice_subs - payment_method_choice_cv - payment_method_choice_wallet as payment_method_choice_account_pay
   from dma.billing_metric_observation
where cast(observation_date as date) between :first_date and :last_date
    -- and observation_year between date_trunc('year', :first_date) and date_trunc('year', :last_date) -- @trino

