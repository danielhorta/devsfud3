/**                                                     
* ===================================================================================================================================
*  Desarrollado por:    Joe Alexander Ayala
*  Fecha:               Enero 30 de 2013
*  Decripción:          Controlador de la pagina PG008_SendCreditCheck que genera el chequeo de crédito
*  @version:            1.0
*  @version:            1.1  26-02-2014	JAAR Se realiza modificacion para permitir que sea posible laconsulta del chequeo con o sin datos
										     de facturtación
* ===================================================================================================================================
**/

public with sharing class CTR008_SendCreditCheck {
    
    public String Codigocuenta { get; set; }
    public String Namecuenta { get; set; }
    public String Clienteunico { get; set; }
    public String identification{ get; set; }
    public Boolean billingdata{ get; set; }
    public Boolean isok{ get; set; }
    public Boolean invoked { get; set; }		//JDHC 19-03-2014 variable para controlar si el servicio es invocado
    public Boolean BlnMessage{ get; set; }
    public String StrMessage{ get; set; }
    public String IdOportunity { get; set; }
    public Quote cotizacion{ get; set; }
    public Opportunity oppcheck{ get; set; }
     public Account opAccount{ get; set; }		//JDHC 19-03-2014
    public list<Requestfinancial__c>Reqfinancial{ get; set; }
    public list<CL008_Sap_ConsCupoCredit_ObjectsSF.DescripcionMsgRs> Msgchequeo{ get; set; }
    public String  strbillingdata{ 
    	get{
    	     if(billingdata)
    	         return 'COMPLETA CON DATOS DE FACTURACION'; 
             else
           		 return 'INCOMPLETA SIN DATOS DE FACTURACION'; 
    	   }  
    	 set; }
    public String strTittlePage {get;set;} //variable que contiene el título de la página visualforce
    public Boolean requestFromsimulation{get;set;} //booleano para indicar si es una simulacion de la cotizacion
    public String strAccion {get;set;}      //cotizazcion o oportunidad
    public ApexPages.Standardcontroller controller;
    public List<CL008_Sap_ConsCupoCredit_ObjectsSF.CreditWorthiness> listCreditWorthiness {get;set;}
    public List<CL008_Sap_ConsCupoCredit_ObjectsSF.CreditWorthiness> resultDetalle{get;set;}
    public List<CL008_Sap_ConsCupoCredit_ObjectsSF.Producto> detallecotizacion{get;set;}//intento 
    public String message {get; set;}
    public Boolean nonconformitiesrequest { get; set; }
    public boolean ChequeoApagado{get;set;}
    public Boolean display { get; set; }
    public String idOperation {get; set;}
    public String severity {get; set;}    
    public String OpportunityId {get;set;}
    public String CotizacionId {get;set;}
    public String OperationCode {get;set;}
    public String ProposalDocumentId {get;set;}
    public String requestFrom{get;set;}
    public String accion{get;set;}
    public String nameCotizacion{get;set;}
    public boolean completeQuote{get;set;}
    public boolean completeCU{get;set;}
    public String selection {get;set;}
    public CL009_SAPlogicCreditCheck scmc;
    public map<ID,CL008_Sap_ConsCupoCredit_ObjectsSF.ResponseChequearCreditos> mapRsChequearCred {get;set;}
    public List<CL008_Sap_ConsCupoCredit_ObjectsSF.CreditWorthiness> listResult {get;set;}
    //public SAP_CreditManagementClient scmc;
    Quote ValCotizacion;
    

 public CTR008_SendCreditCheck(){
 	      Utils_Chequeocredito__c Utilschequeo = Utils_Chequeocredito__c.getAll().get('Colombia');
 	      nonconformitiesrequest = Utilschequeo.Validar_no_conformidades__c;
 	      ChequeoApagado		 = Utilschequeo.Chequeo_Apagado__c;
 	      system.debug('Validar_No_conformidades?  '+ nonconformitiesrequest + 'ChequeoApagado ' + ChequeoApagado); 
 	      
 	      isok = true;
 	      invoked = true;		//JHDC 19-03-2014
 	     BlnMessage = false;
        if(Apexpages.currentPage().getParameters().get('OperationCode')!=null && Apexpages.currentPage().getParameters().get('OperationCode')=='CHEQUEO'){
             system.debug('\n\n Apexpages.currentPage_getParameters_requestFrom'+ Apexpages.currentPage().getParameters().get('requestFrom'));  
            if(Apexpages.currentPage().getParameters().get('requestFrom')== 'COTIZACION')
            {
              strTittlePage='Simulación de Chequeo de crédito';
              requestFromsimulation = true;
              
            } else{
              strTittlePage='Chequeo de crédito';
              requestFromsimulation = false;
            }
            
        }    
        Map<String, String> mapValuesByKeyUrl = ApexPages.currentPage().getParameters();
        if( mapValuesByKeyUrl.containsKey( 'accion' ) )
           strAccion = mapValuesByKeyUrl.get( 'accion' );
 } 

public PageReference lanzarProceso()
    {
      system.debug('\n\n >>>>----strAccion    '+strAccion);   
          //if(requestFromsimulation) 
          //{
            //SIMULACION = COTIZACION
            system.debug('invoked::: '+invoked);
            this.controller  = controller;
            system.debug('\n\n >>>>----requestFromsimulation    '+requestFromsimulation);   
            if(requestFromsimulation)
            {
            	CotizacionId     = Apexpages.currentPage().getParameters().get('PresupuestoId');
            }else
            {
            	IdOportunity     = Apexpages.currentPage().getParameters().get('PresupuestoId');
            	oppcheck = getOpportunity(IdOportunity);
            	//opAccount = [SELECT Id,Pendiente_pago__c from Account where Id =: oppcheck.AccountId];
            	//system.debug('Idaccount: opaccount: ' + opAccount);
            	system.debug('IdOportunity_12 '+ IdOportunity + oppcheck);
            	if(oppcheck.SyncedQuoteId <> null)
            	{
            	  cotizacion = [SELECT IsSyncing,Id,OpportunityId,RecordTypeId,blocked_quote__c,(SELECT Blocked_BillingData__c,Id FROM Datos_facturacion__r)  FROM Quote WHERE IsSyncing = true AND OpportunityId =: IdOportunity]; 
            	} else
            	{
	        		this.setMsg(2, 'No ha sincronizado ninguna cotización en esta oportunidad, por lo tanto no es posible continuar con el proceso ' );
	        	    this.billingdata  = false;
	        	    BlnMessage = true;
	        		isok = false;
	        	    return null;
            	}  
            	
            	CotizacionId = cotizacion.Id;
            	if(oppcheck.CreditCheckCode__c <> null && (oppcheck.StageName == '06 Cerrada Entregada Fulfillment'||oppcheck.StageName == '05 Cerrada Entregada Facturación')  )
            	{
	        		 //gestiona aprbación de fulfillment
	        		 
	        		 this.BlnMessage = true;
	        		 isok = false;
	        		 this.billingdata  = false;
	        		 this.setMsg(0, 'No es posible volver a ejecutar el chequeo de crédito, la oportunidad se encuentra en etapa: ' +oppcheck.StageName );
	        	     return null;
            	}
            /* VERIFICACION DE NO CONFORMIDADES --------------------------------------------------------------------------------------------------------------------
             *JAAR 11-03-2014 Se realiza validacion para que no permita enviar aprovación si la oportunidad tiene asociada una no conformidad abierta o en proceso 
             *******************************************************************************************************************************************************/
            	if(oppcheck.Estado_No_conformidad__c <>null) 
            	{
            		//JAAR 20-03-2014 Se configura parametro desde donde se controla la obligatoriedad de la validacion de las no conformidades 
            		
            		if(nonconformitiesrequest <> null) 
            		{
            			if(nonconformitiesrequest == true)
            			{
            				if(oppcheck.Estado_No_conformidad__c == 'EN PROCESO' || oppcheck.Estado_No_conformidad__c == 'ABIERTA')
			            		{
			            	     this.billingdata  = false;
			            		 isok = false;
			            		 BlnMessage = true;
			            		 this.setMsg(0, 'No es posible enviar a aprobación si aun no ha cerrado la no conformidad por la que fue devuelta: '  );
			            	     return null;
			            		}
            			}
            		}
            		
            	}
            	
            	if(oppcheck.Estado_No_conformidad_Cartera__c <>null) 
            	{
            		//JAAR 20-03-2014 Se configura parametro desde donde se controla la obligatoriedad de la validacion de las no conformidades 
            		if(nonconformitiesrequest <> null) 
            		{
            			if(nonconformitiesrequest == true)
            			{
            				if(oppcheck.Estado_No_conformidad_Cartera__c  == 'EN PROCESO'||oppcheck.Estado_No_conformidad_Cartera__c  == 'ABIERTA')
			            		{
			            	     this.billingdata  = false;
			            		 isok = false;
			            		 BlnMessage = true;
			            		 this.setMsg(0, 'No es posible enviar a aprobación si aun no ha cerrado la no conformidad por la que fue devuelta: '  );
			            	     return null;
			            		}
            			}
            		}
            		
            	}
                
 
 			/***********************VALIDACION DE PENDIENTES DE PAGO *******************************************************************************
            **JDHC 19-03-2014 Se realiza validacion de 
            **
            ************************************************************************************************************************************/
            if(oppcheck.Account.Pendiente_pago__c == true){
            //1 - Actualiza la marca de chequero de crédito de la oportunidad
               	     oppcheck.IsCreditAnalysisRequired__c	=  false;
               	     oppcheck.IsCreditExceptionAllowed__c	=  false;
                 	  //Se iguala el  campo Fecha_cerrada_entregada_facturacion__c a Fecha_Entregada_Facturacion__c ya que pasa automaticamente a fulfillment 
               	    oppcheck.Fecha_Entregada_Facturacion__c 			= system.now();
               	    oppcheck.Fecha_cerrada_entregada_facturacion__c 	= null;
               	    oppcheck.Comentarios_fulfillment__c				= '';
               	    oppcheck.Comentarios_Cartera__c					= '';
               	     //se limpian los campos de la gestion de fulfillment ya que iniciará nuevamente el flujo de aprobación
               	    oppcheck.Responsable_fulfillmet__c					=null;
               	    oppcheck.Semaforostatus__c							=null;
               	    oppcheck.Status_fulfillment__c						=null;
           	     	oppcheck.Comentarios_fulfillment__c				='';
               	    oppcheck.Fecha_Entregada_Fulfillment__c			=null;
               	    oppcheck.Fecha_cerrada_fulfillment__c				=null;
               	    oppcheck.Estado_No_conformidad__c          		=null;
               	    oppcheck.Estado_No_conformidad_Cartera__c  		= null;
    			    Requestfinancial__c checfin = new Requestfinancial__c();
        			//JAAR si el chequeo automatico fue aprobado ingresa directo a fulfillment
           	     	oppcheck.StageName 					= '05 Cerrada Entregada Facturación';
           	     	oppcheck.Fecha_Entregada_Fulfillment__c	=system.now();
           	     	//JAAR no pasa por facturación la fecha de entrada y salida es la misma
           	     	oppcheck.Fecha_Entregada_Facturacion__c			 	= system.now();
					oppcheck.Fecha_cerrada_entregada_facturacion__c		= null;
					checfin.Fecha_Entregada_Facturacion__c  			= system.now();
					checfin.Date_of_Approval__c				    		= null;
					oppcheck.automaticresult__c			= 'RECHAZADO';
	             	oppcheck.endcheckup__c				= 'EN PROCESO';
	             	oppcheck.Semaforostatus__c			= 'Yellow';
	        	    oppcheck.CreditCheckCode__c 		= 'CUENTA PENDIENTE DE PAGO'; 
	        	    oppcheck.Comentarios_Cartera__c 	= 'La cuenta está pendiente de pago';	         	
	             	//------CHEQUEO APROBADO---------------------------------------------------------
	                checfin.CreditCheckCode__c 			= 'CUENTA PENDIENTE DE PAGO'; 
               	    checfin.IsCreditAnalysisRequired__c	= false;
               	    checfin.IsCreditExceptionAllowed__c	= false;
               	    checfin.LastCreditCheck__c            	= system.now();
               	    checfin.Idoportunity__c 				= IdOportunity;
               	    checfin.Chequeo_vigente__c				= true;
               	    system.debug('relacion_quotes  '+oppcheck.Quotes);
               	    checfin.Monto__c						= oppcheck.Quotes.get(0).GrandTotal;
               	    checfin.Status_del_chequeo__c			= 'EN PROCESO';
               	    checfin.automaticresult__c				= 'RECHAZADO';
               	    checfin.User_approver__c				= 'SISTEMA';
               	    checfin.Tipo_de_solicitud__c			= '';
               	    checfin.Mensajes_Chequeo__c 			= 'La cuenta está pendiente de pago';	
		            Reqfinancial = getRequestfinancial(IdOportunity, checfin.CreditCheckCode__c );
               	     if(Reqfinancial <> null)
               	     {
               	     	for (Requestfinancial__c rf:Reqfinancial)
                   	     {
                   	     	rf.Chequeo_vigente__c = false;
                   	     }
               	     }
               	     // JAAR Bloquear el dato de facturación posterior al envio del chequeo --
               	     Block_data();
               	     
               	     try{
               	     	    update oppcheck;
               	     	    if(Reqfinancial <> null)
               	     	    {
               	     	      update Reqfinancial;
               	     	    }
               	     	    insert checfin;	
               	     	   
               	     	}catch(system.exception e)
	               	    {
	               	     system.debug('No fue posible actualizar la opp  '+e);
	               	    }
        			this.billingdata  = false;
        		    this.BlnMessage   = true;
            		isok = false;
            		this.setMsg(1, 'La cuenta se encuentra pendiente de pago, pasará directamente a cartera para su verificación '  );
            		return null;
            }
 
            /***********************VALIDACION DE VTAS VALOR CERO *******************************************************************************
            **JAAR 17-03-2014 Se realiza cambio para permitir que las oportunidades con valor cero no requieran paso por facturacion
            **
            ************************************************************************************************************************************/        	
            	if(oppcheck.Amount <>null) 
            	{
            		if(oppcheck.Amount == 0)
            		{
    			     //1 - Actualiza la marca de chequero de crédito de la oportunidad
               	     oppcheck.IsCreditAnalysisRequired__c	=  false;
               	     oppcheck.IsCreditExceptionAllowed__c	=  false;
               	     
	                 //Se iguala el  campo Fecha_cerrada_entregada_facturacion__c a Fecha_Entregada_Facturacion__c ya que pasa automaticamente a fulfillment 
               	     oppcheck.Fecha_Entregada_Facturacion__c 			= system.now();
               	     oppcheck.Fecha_cerrada_entregada_facturacion__c 	= system.now();
               	     oppcheck.Comentarios_fulfillment__c				= '';
               	     oppcheck.Comentarios_Cartera__c					= '';
               	     //se limpian los campos de la gestion de fulfillment ya que iniciará nuevamente el flujo de aprobación
               	     oppcheck.Responsable_fulfillmet__c					=null;
               	     oppcheck.Semaforostatus__c							=null;
               	     oppcheck.Status_fulfillment__c						=null;
           	     	 oppcheck.Comentarios_fulfillment__c				='';
               	     oppcheck.Fecha_Entregada_Fulfillment__c			=null;
               	     oppcheck.Fecha_cerrada_fulfillment__c				=null; 
               	     oppcheck.Estado_No_conformidad__c          		=null;
               	     oppcheck.Estado_No_conformidad_Cartera__c  		= null;
    			     Requestfinancial__c checfin = new Requestfinancial__c();
        			//JAAR si el chequeo automatico fue aprobado ingresa directo a fulfillment
           	     	 oppcheck.StageName 					= '06 Cerrada Entregada Fulfillment';
           	     	 oppcheck.Fecha_Entregada_Fulfillment__c	=system.now();
           	     	 //JAAR no pasa por facturación la fecha de entrada y salida es la misma
           	     	 oppcheck.Fecha_Entregada_Facturacion__c			 	= system.now();
					 oppcheck.Fecha_cerrada_entregada_facturacion__c		= System.now();
					 checfin.Fecha_Entregada_Facturacion__c  			= system.now();
					 checfin.Date_of_Approval__c				    		= system.now();
					 oppcheck.automaticresult__c			= 'APROBADO';
	             	 oppcheck.endcheckup__c				= 'APROBADO';
	             	 oppcheck.Semaforostatus__c			= 'Green';
	        	     oppcheck.CreditCheckCode__c 		= 'VALOR CERO'; 
	        	     oppcheck.Comentarios_Cartera__c 	= 'Oportunidad de valor cero aprobada automaticamente por el sistema';	         	
	             	 //------CHEQUEO APROBADO---------------------------------------------------------
	                 checfin.CreditCheckCode__c 			= 'VALOR CERO'; 
               	     checfin.IsCreditAnalysisRequired__c	= false;
               	     checfin.IsCreditExceptionAllowed__c	= false;
               	     checfin.LastCreditCheck__c            	= system.now();
               	     checfin.Idoportunity__c 				= IdOportunity;
               	     checfin.Chequeo_vigente__c				= true;
               	     system.debug('relacion_quotes  '+oppcheck.Quotes);
               	     checfin.Monto__c						= oppcheck.Quotes.get(0).GrandTotal;
               	     checfin.Status_del_chequeo__c			= 'APROBADO';
               	     checfin.automaticresult__c				= 'APROBADO';
               	     checfin.User_approver__c				= 'SISTEMA';
               	     checfin.Tipo_de_solicitud__c			= '';
               	     checfin.Mensajes_Chequeo__c 			= 'Oportunidad de valor cero aprobada automaticamente por el sistema';	
		                   	     
		             Reqfinancial = getRequestfinancial(IdOportunity, checfin.CreditCheckCode__c );
               	     if(Reqfinancial <> null)
               	     {
               	     	for (Requestfinancial__c rf:Reqfinancial)
                   	     {
                   	     	rf.Chequeo_vigente__c = false;
                   	     }
               	     }
               	     
               	     // JAAR Bloquear el dato de facturación posterior al envio del chequeo --
               	     Block_data();
               	    
               	     try{
               	     	    update oppcheck;
               	     	    if(Reqfinancial <> null)
               	     	    {
               	     	      update Reqfinancial;
               	     	    }
               	     	    insert checfin;	
               	     	     
               	     	}catch(system.exception e)
	               	    {
	               	     system.debug('No fue posible actualizar la opp  '+e);
	               	    }
        			this.billingdata  = false;
        		    this.BlnMessage   = true;
            		isok = false;
            		this.setMsg(1, 'Oportunidad de valor cero no requiere aprobación de cartera, pasará directamente a Gestión fulfillment '  );
            		//this.StrMessage = 'Oportunidad de valor cero no requiere aprobación de cartera pasará  directamente a Gestión fulfillment ';
            		return null;
            		}
            		
            	}
             //====================================================== fin opp valor cero ============================================== 
             
  
            /***********************VALIDACION DE TOKEN VTA ON LINE ****************************************************************************
            **JAAR 17-03-2014 solo se realiza en caso de que la venta se haya realizado desde fuente externa y se tenga un token para ingresar a 
            **la oportunidad en cuyo caso no requieran paso por facturacion
            ************************************************************************************************************************************/
            if(oppcheck.Token_venta_en_linea__c <>null) 
            {
            	if(!validaRTextTokenonline(oppcheck.Token_venta_en_linea__c))
                 {
                   this.billingdata  = false; 
        		   this.BlnMessage   = true;
            	   isok = false;
                   this.setMsg(2, 'El token de venta ON-LINE ingresado en la oportunidad, no cumple con las caracteristicas especificadas, por favor verifiquelo y vuelva a intentarlo'  );
                   return null;  
                 }else
                 {
                   system.debug('Supero_la_validacion_del_token:online');
                    //1 - Actualiza la marca de chequero de crédito de la oportunidad
               	    oppcheck.IsCreditAnalysisRequired__c	=  false;
               	    oppcheck.IsCreditExceptionAllowed__c	=  false;
               	    //2 - bloquea la oportunidad para que no pueda ser editada despues del chequeo
	                oppcheck.blocked_opportunity__c        = true;
	                oppcheck.RecordTypeId				   = '01240000000IYWbAAO';
               	    //Se iguala el  campo Fecha_cerrada_entregada_facturacion__c a Fecha_Entregada_Facturacion__c ya que pasa automaticamente a fulfillment 
               	    oppcheck.Fecha_Entregada_Facturacion__c 			= system.now();
               	    oppcheck.Fecha_cerrada_entregada_facturacion__c 	= system.now();
               	    oppcheck.Comentarios_fulfillment__c				= '';
               	    oppcheck.Comentarios_Cartera__c					= '';
               	    //se limpian los campos de la gestion de fulfillment ya que iniciará nuevamente el flujo de aprobación
               	    oppcheck.Responsable_fulfillmet__c					=null;
               	    oppcheck.Semaforostatus__c							=null;
               	    oppcheck.Status_fulfillment__c						=null;
           	     	oppcheck.Comentarios_fulfillment__c				='';
               	    oppcheck.Fecha_Entregada_Fulfillment__c			=null;
               	    oppcheck.Fecha_cerrada_fulfillment__c				=null;
               	    oppcheck.Estado_No_conformidad__c          		=null;
               	    oppcheck.Estado_No_conformidad_Cartera__c  		= null;
    			    Requestfinancial__c checfin = new Requestfinancial__c();
        			//JAAR si el chequeo automatico fue aprobado ingresa directo a fulfillment
           	     	oppcheck.StageName 					= '06 Cerrada Entregada Fulfillment';
           	     	oppcheck.Fecha_Entregada_Fulfillment__c	=system.now();
           	     	//JAAR no pasa por facturación la fecha de entrada y salida es la misma
           	     	oppcheck.Fecha_Entregada_Facturacion__c			 	= system.now();
					oppcheck.Fecha_cerrada_entregada_facturacion__c		= System.now();
					checfin.Fecha_Entregada_Facturacion__c  			= system.now();
					checfin.Date_of_Approval__c				    		= system.now();
					oppcheck.automaticresult__c			= 'APROBADO';
	             	oppcheck.endcheckup__c				= 'APROBADO';
	             	oppcheck.Semaforostatus__c			= 'Green';
	        	    oppcheck.CreditCheckCode__c 		= 'VENTA ON-LINE'; 
	        	    oppcheck.Comentarios_Cartera__c 	= 'Posee token de Venta On-Line,Oportunidad aprobada automaticamente por el sistema';	         	
	             	//------CHEQUEO APROBADO---------------------------------------------------------
	                checfin.CreditCheckCode__c 			= 'VENTA ON-LINE'; 
               	    checfin.IsCreditAnalysisRequired__c	= false;
               	    checfin.IsCreditExceptionAllowed__c	= false;
               	    checfin.LastCreditCheck__c            	= system.now();
               	    checfin.Idoportunity__c 				= IdOportunity;
               	    checfin.Chequeo_vigente__c				= true;
               	    system.debug('relacion_quotes  '+oppcheck.Quotes);
               	    checfin.Monto__c						= oppcheck.Quotes.get(0).GrandTotal;
               	    checfin.Status_del_chequeo__c			= 'APROBADO';
               	    checfin.automaticresult__c				= 'APROBADO';
               	    checfin.User_approver__c				= 'SISTEMA';
               	    checfin.Tipo_de_solicitud__c			= '';
               	    checfin.Mensajes_Chequeo__c 			= 'Posee token de Venta On-Line,Oportunidad aprobada automaticamente por el sistema';	
		            Reqfinancial = getRequestfinancial(IdOportunity, checfin.CreditCheckCode__c );
               	     if(Reqfinancial <> null)
               	     {
               	     	for (Requestfinancial__c rf:Reqfinancial)
                   	     {
                   	     	rf.Chequeo_vigente__c = false;
                   	     }
               	     }
               	     // JAAR Bloquear el dato de facturación posterior al envio del chequeo --
               	     Block_data();
               	     
               	     try{
               	     	    update oppcheck;
               	     	    if(Reqfinancial <> null)
               	     	    {
               	     	      update Reqfinancial;
               	     	    }
               	     	    insert checfin;	
               	     	   
               	     	}catch(system.exception e)
	               	    {
	               	     system.debug('No fue posible actualizar la opp  '+e);
	               	    }
        			this.billingdata  = false;
        		    this.BlnMessage   = true;
            		isok = false;
            		this.setMsg(1, 'Oportunidad con token de Venta On-Line, no requiere aprobación de cartera, pasará directamente a Gestión fulfillment '  );
            		return null;
            	}
                 
            } 
            
            
            //=========================================================================================================================
            	
            	
            	
            }
            
            system.debug('CotizacionId_1 '+ CotizacionId);          
            OperationCode    = Apexpages.currentPage().getParameters().get('OperationCode');
            requestFrom      = Apexpages.currentPage().getParameters().get('requestFrom');
            accion           = Apexpages.currentPage().getParameters().get('accion');
            object obj;
            object objrequest;
            selection='0';
            system.debug('requestFrom==>>>  '+ requestFrom);
            // Leer el registro de la Cotizacion del paraemtro enviado por URL 
            this.ValCotizacion = this.getQuoteById(CotizacionId);  // Read Cotizacion 
            this.Codigocuenta  =  ValCotizacion.Opportunity.Account.Codigo_cuenta__c;  
            this.Namecuenta  =  ValCotizacion.Opportunity.Account.Name;
            if(ValCotizacion.Opportunity.Account.Codigo_cliente_unico__c <> null)
            {
                system.debug('\n\n Codigo_cliente_unico__c_de_la_cotizacion  '+ ValCotizacion.Opportunity.Account.Codigo_cliente_unico__c ); 
                this.Clienteunico  = String.valueof(ValCotizacion.Opportunity.Account.Codigo_cliente_unico__c);
                this.identification = String.valueof(ValCotizacion.Opportunity.Account.Numero_identificacion__c);
                completeCU = true;
            }else
            {
                 system.debug('\n\n Clienteunico_inicial  '+ Clienteunico +'CotizacionId_1  ' + CotizacionId ); 
                 
                system.debug('\n\n Para realizar el chequeo de credito la cuenta debe tener codigo de cliente Unico contacte al administrador');   
                this.Clienteunico  = 'No se encontró información en salesforce';
                this.identification = 'No se encontró información en salesforce';
                completeCU = false;
            }
            
            this.nameCotizacion = 'Respuesta del chequeo de crédito para : ' + this.ValCotizacion.Name;
            
             // Valida que la cotización tenga datos de facturación y productos para consumir el sw
            completeQuote=this.ValidateCotizacion(this.ValCotizacion,requestFromsimulation);      
             if (completeQuote==true && completeCU == true)
             {
                //llamar clase que contiene la logica de la construccion del request del chequeo
                this.scmc = new cl009_saplogiccreditcheck(CotizacionId,OperationCode,requestFrom,requestFromsimulation); 
                system.debug('Entro_a_proccesCheckCreditscmc'+scmc);
                try
                 {
                    system.debug('\n\n 1-Antes_proccesCheckCredit');
                    obj= this.scmc.proccesCheckCredit();
                    
                    system.debug('\n\n mi_obj======>>>'+obj);
                    
                   
                    
                 }catch(system.exception e)
                 {
                    system.debug('ver error 1 -->'+'Error_al_invocar_el_web service de chequeo de credito');
                    //this.setMsg(0, 'Error al invocar el web service de chequeo de credito'); 
                    BlnMessage = true;
                    isok = false;
                    invoked = false;		//JDHC 19-03-2014
                    this.billingdata  = false;
                    //return null;
                 }
                 
                 
                  //JDHC 19-03-2014 se evalua si el servicio fue invocado y si no es una simulacion
                  system.debug('invoked1::: '+invoked);
                   system.debug('rfs::: '+requestFromsimulation);
                 if (invoked == false && requestFromsimulation == false){		
               	     oppcheck.IsCreditAnalysisRequired__c	=  false;
               	     oppcheck.IsCreditExceptionAllowed__c	=  false;
                 	  //Se iguala el  campo Fecha_cerrada_entregada_facturacion__c a Fecha_Entregada_Facturacion__c ya que pasa automaticamente a fulfillment 
               	    oppcheck.Fecha_Entregada_Facturacion__c 			= system.now();
               	    oppcheck.Fecha_cerrada_entregada_facturacion__c		= null;
               	    oppcheck.Comentarios_fulfillment__c					= '';
               	    oppcheck.Comentarios_Cartera__c						= '';
               	     //se limpian los campos de la gestion de fulfillment ya que iniciará nuevamente el flujo de aprobación
               	    oppcheck.Responsable_fulfillmet__c					=null;
               	    oppcheck.Semaforostatus__c							=null;
               	    oppcheck.Status_fulfillment__c						=null;
           	     	oppcheck.Comentarios_fulfillment__c					='';
               	    oppcheck.Fecha_Entregada_Fulfillment__c				=null;
               	    oppcheck.Fecha_cerrada_fulfillment__c				=null;
               	    oppcheck.Estado_No_conformidad__c          			=null;
               	    oppcheck.Estado_No_conformidad_Cartera__c  			= null;
    			    Requestfinancial__c checfin = new Requestfinancial__c();
        			//JAAR si el chequeo automatico fue aprobado ingresa directo a fulfillment
           	     	oppcheck.StageName 									= '05 Cerrada Entregada Facturación';
           	     	oppcheck.Fecha_Entregada_Fulfillment__c				=system.now();
           	     	//JAAR no pasa por facturación la fecha de entrada y salida es la misma
           	     	//oppcheck.Fecha_Entregada_Facturacion__c			 	= system.now();
					
					checfin.Fecha_Entregada_Facturacion__c  			= system.now();
					//checfin.Date_of_Approval__c				    		= system.now();
					oppcheck.automaticresult__c			= 'RECHAZADO';
	             	oppcheck.endcheckup__c				= 'EN PROCESO';
	             	oppcheck.Semaforostatus__c			= 'Yellow';
	        	    oppcheck.CreditCheckCode__c 		= 'ERROR DE CONEXION'; 
	        	    oppcheck.Comentarios_Cartera__c 	= 'El sistema no se pudo conectar al servicio de chequeo';	         	
	             	//------CHEQUEO APROBADO---------------------------------------------------------
	                checfin.CreditCheckCode__c 			= 'ERROR DE CONEXION'; 
               	    checfin.IsCreditAnalysisRequired__c	= false;
               	    checfin.IsCreditExceptionAllowed__c	= false;
               	    checfin.LastCreditCheck__c            	= system.now();
               	    checfin.Idoportunity__c 				= IdOportunity;
               	    checfin.Chequeo_vigente__c				= true;
               	    system.debug('relacion_quotes  '+oppcheck.Quotes);
               	    checfin.Monto__c						= oppcheck.Quotes.get(0).GrandTotal;
               	    checfin.Status_del_chequeo__c			= 'EN PROCESO';
               	    checfin.automaticresult__c				= 'RECHAZADO';
               	    checfin.User_approver__c				= 'SISTEMA';
               	    checfin.Tipo_de_solicitud__c			= '';
               	    checfin.Mensajes_Chequeo__c 			= 'El sistema no se pudo conectar al servicio de chequeo';	
		            Reqfinancial = getRequestfinancial(IdOportunity, checfin.CreditCheckCode__c );
		            
               	     if(Reqfinancial <> null)
               	     {
               	     	for (Requestfinancial__c rf:Reqfinancial)
                   	     {
                   	     	rf.Chequeo_vigente__c = false;
                   	     }
               	     }
               	     // JAAR Bloquear el dato de facturación posterior al envio del chequeo --
               	     Block_data();
               	     
               	     try{
               	     	    update oppcheck;
               	     	    if(Reqfinancial <> null)
               	     	    {
               	     	      update Reqfinancial;
               	     	    }
               	     	    insert checfin;	
               	     	   
               	     	}catch(system.exception e)
	               	    {
	               	     system.debug('No fue posible actualizar la opp  '+e);
	               	    }
        			this.billingdata  = false;
        		    this.BlnMessage   = true;
            		isok = false;
            		this.setMsg(1, 'Se presento error de conexion con el servicio, pasará directamente al area de cartera para ser validado de forma manual '  );
            		return null;
                 }
                                  
                 if (obj != null)
                 {
                    //almacena  la inf del obj en una lista para mostrar en la respuesta 
                    
                    detallecotizacion = scmc.listProducts;
                    system.debug('detallecotizacion_request '+ detallecotizacion );
                   
                   //-----------------------------------------------------------------------------
                   
                   /*
                    try
                    {
                      system.debug('@@obj--> '+obj);
                      Boolean respuesta=(Boolean)obj;
                      
                      if (respuesta==true)
                      {
                        try{
                             system.debug('@@this.ValCotizacion.id--> '+this.ValCotizacion.id);
                           } catch(Exception ex1)
                           {
                            system.debug('ex.getMessage(): '+ex1.getMessage());
                            this.setMsg(0, ex1.getMessage());
                           }  
                        //redireccióna depende de donde se haya hecho el llamado:SIMULACION o CHEQUEO
                         if (strAccion == 'SIMULACION')  
                            {                                  
                               return null;
                               // return this.InvokeFinancialValidation();       
                            }   
                          else if (strAccion == 'CHEQUEO')  
                          {
                                //pendiente
                          }                                            
                      
                     }                           
                  } catch(Exception ex)
                  {
                    system.debug('ver error 3-->'+'ERROR_CHQ');
                    this.setMsg(0, 'Error obteniendo respuesta');
                  }
                  */
                  //JAAR agrega el response al map para obtener respuesta directa 
                  mapRsChequearCred=(map<ID,CL008_Sap_ConsCupoCredit_ObjectsSF.ResponseChequearCreditos>)obj;
                  
                   system.debug('\n\n mapRsChequearCred====>>>>'+mapRsChequearCred);
               }else 
               {
                system.debug('\n\n ver_error_4-->'+'obj = null');
                this.setMsg(2, 'Error en el quequeo de credito');
               }
              
                listCreditWorthiness = this.getRespuestasChequeCredito();  
                system.debug('\n\n JAAR nuevo_mi_listCreditWorthiness_post  '+ listCreditWorthiness);
                
                if(listCreditWorthiness[0].creditLimit <> null)
                {}else
                {
                    //-----
		            if(!requestFromsimulation) 
		               {
		               	/***********************CLIENTE NO EXISTE EN SAP *******************************************************************************
			            **JAAR 22-03-2014 Si el cliente no existe en SAP envia la oportunidad al area de cartera para su validación 
			            **
			            ************************************************************************************************************************************/
			            
			            //1 - Actualiza la marca de chequero de crédito de la oportunidad
			               	    oppcheck.IsCreditAnalysisRequired__c	=  false;
			               	    oppcheck.IsCreditExceptionAllowed__c	=  false;
			                 	//Se iguala el  campo Fecha_cerrada_entregada_facturacion__c a Fecha_Entregada_Facturacion__c ya que pasa automaticamente a fulfillment 
			               	    oppcheck.Fecha_Entregada_Facturacion__c 			= system.now();
			               	    oppcheck.Fecha_cerrada_entregada_facturacion__c 	= null;
			               	    oppcheck.Comentarios_fulfillment__c				= '';
			               	    oppcheck.Comentarios_Cartera__c					= '';
			               	     //se limpian los campos de la gestion de fulfillment ya que iniciará nuevamente el flujo de aprobación
			               	    oppcheck.Responsable_fulfillmet__c					=null;
			               	    oppcheck.Semaforostatus__c							=null;
			               	    oppcheck.Status_fulfillment__c						=null;
			           	     	oppcheck.Comentarios_fulfillment__c					='';
			               	    oppcheck.Fecha_Entregada_Fulfillment__c				=null;
			               	    oppcheck.Fecha_cerrada_fulfillment__c				=null;
			               	    oppcheck.Estado_No_conformidad__c          			=null;
			               	    oppcheck.Estado_No_conformidad_Cartera__c  			= null;
			    			    Requestfinancial__c checfin 						= new Requestfinancial__c();
			        			//JAAR si el chequeo automatico fue aprobado ingresa directo a fulfillment
			           	     	oppcheck.StageName 									= '05 Cerrada Entregada Facturación';
			           	     	oppcheck.Fecha_Entregada_Fulfillment__c				=system.now();
			           	     	//JAAR no pasa por facturación la fecha de entrada y salida es la misma
			           	     	oppcheck.Fecha_Entregada_Facturacion__c			 	= system.now();
								oppcheck.Fecha_cerrada_entregada_facturacion__c		= null;
								checfin.Fecha_Entregada_Facturacion__c  			= system.now();
								checfin.Date_of_Approval__c				    		= null;
								oppcheck.automaticresult__c							= 'RECHAZADO';
			             	    oppcheck.endcheckup__c								= 'EN PROCESO';
				             	oppcheck.Semaforostatus__c							= 'Yellow';
				        	    oppcheck.CreditCheckCode__c 						= 'CLIENTE NO EXISTE EN SAP'; 
				        	    oppcheck.Comentarios_Cartera__c 					= 'Posiblemente el cliente no existe en SAP';	         	
				             	//------CHEQUEO APROBADO---------------------------------------------------------
				                checfin.CreditCheckCode__c 							= 'CLIENTE NO EXISTE EN SAP'; 
			               	    checfin.IsCreditAnalysisRequired__c					= false;
			               	    checfin.IsCreditExceptionAllowed__c					= false;
			               	    checfin.LastCreditCheck__c            				= system.now();
			               	    checfin.Idoportunity__c 							= IdOportunity;
			               	    checfin.Chequeo_vigente__c							= true;
			               	    system.debug('relacion_quotes  '+oppcheck.Quotes);
			               	    checfin.Monto__c									= oppcheck.Quotes.get(0).GrandTotal;
			               	    checfin.Status_del_chequeo__c						= 'EN PROCESO';
			               	    checfin.automaticresult__c							= 'RECHAZADO';
			               	    checfin.User_approver__c							= 'SISTEMA';
			               	    checfin.Tipo_de_solicitud__c						= '';
			               	    checfin.Mensajes_Chequeo__c 						= 'La cuenta está pendiente de pago';	
					            Reqfinancial = getRequestfinancial(IdOportunity, checfin.CreditCheckCode__c );
			               	     if(Reqfinancial <> null)
			               	     {
			               	     	for (Requestfinancial__c rf:Reqfinancial)
			                   	     {
			                   	     	rf.Chequeo_vigente__c = false;
			                   	     }
			               	     }
			               	     // JAAR Bloquear el dato de facturación posterior al envio del chequeo --
			               	     Block_data();
			               	     try{
			               	     	    update oppcheck;
			               	     	    if(Reqfinancial <> null)
			               	     	    {
			               	     	      update Reqfinancial;
			               	     	    }
			               	     	    insert checfin;	
			               	     	   
			               	     	}catch(system.exception e)
				               	    {
				               	     system.debug('No fue posible actualizar la opp  '+e);
				               	    }
			        			this.billingdata  = false;
			        		    this.BlnMessage   = true;
			            		isok = false;
			            		this.setMsg(1, 'Posiblemente el cliente no existe en SAP, pasará directamente a cartera para su verificación '  );
			            		return null;
			           }else
		               {
		               	return null;
		               }
		          //-----
                }
              system.debug('valor_de_requestFromsimulation   '+requestFromsimulation);
              if(!requestFromsimulation) 
               { 
	                //JAAR Almacenar la respuesta del chequeo de crédito en salesforce *********************************************************
	                for(CL008_Sap_ConsCupoCredit_ObjectsSF.CreditWorthiness response : listCreditWorthiness)
	                {
	                	system.debug('response=====>>>   '+response);
	                	system.debug('response_checkingDescription=====>>>   '+response.checkingDescription);
	                	system.debug('response.parInfo_Adicional_CM   ' +response.parInfo_Adicional_CM);
	                	system.debug('response.parInfo_Adicional_CM_permiteExcepcion   ' +response.parInfo_Adicional_CM.permiteExcepcion);
	                	system.debug('response.parInfo_Adicional_CM_requiereEstudio   ' +response.parInfo_Adicional_CM.requiereEstudio);
	                
	                	if(response.indicador != null )
	                	{
	                		
	            		if(response.checkingDescription                != null &&
	                       response.indicador                          != null &&
	                       response.permiteExcepcion                   != null &&
	                       response.RequiereEstudio                    != null &&
	                       response.riskClass.validityPeriod.endDate   != null)
	                       {
	                   	     oppcheck = getOpportunity(IdOportunity);
	                   	     system.debug('oportunidad_a_mod '+oppcheck);
	                   	     
	                   	     //1 - Actualiza la marca de chequero de crédito de la oportunidad
	                   	     oppcheck.CreditCheckCode__c 			= response.checkingDescription;
	                   	     oppcheck.CreditLimitValidUntilDate__c	= response.riskClass.validityPeriod.endDate;
	                   	     oppcheck.IsCreditAnalysisRequired__c	= response.RequiereEstudio;
	                   	     oppcheck.IsCreditExceptionAllowed__c	= response.permiteExcepcion;
	                   	     oppcheck.LastCreditCheck__c            = system.now();  
	                   	     
	                   	     //2 - bloquea la oportunidad para que no pueda ser editada despues del chequeo
	                   	     oppcheck.blocked_opportunity__c        = true;
	                   	     
	                   	     oppcheck.Fecha_Entregada_Fulfillment__c  = null;
	                   	     //se borra el campo Fecha_cerrada_entregada_facturacion__c ya que si se realizo de nuevo el chequeo debe resetear el ANS
	                   	     oppcheck.Fecha_Entregada_Facturacion__c = system.now();
	                   	     oppcheck.Fecha_cerrada_entregada_facturacion__c = null;
	                   	     oppcheck.Comentarios_fulfillment__c			= '';
	                   	     oppcheck.Comentarios_Cartera__c				= '';
	                   	     //se limpian los campos de la gestion de fulfillment ya que iniciará nuevamente el flujo de aprobación
	                   	     oppcheck.Responsable_fulfillmet__c		=null;
	                   	     oppcheck.Semaforostatus__c				=null;
	                   	     oppcheck.Status_fulfillment__c			=null;
                   	     	 oppcheck.Comentarios_fulfillment__c	='';
	                   	     oppcheck.Fecha_Entregada_Fulfillment__c	=null;
	                   	    
	                   	     oppcheck.Fecha_cerrada_fulfillment__c		=null;
	                   	     oppcheck.Estado_No_conformidad__c          =null;
	                   	     oppcheck.Estado_No_conformidad_Cartera__c  = null;
	                   	     
	                   	     
	                   	     //JAAR Bloquear el dato de facturación posterior al envio del chequeo ----------------------------------
		               	     Block_data();
		               	     /*
		               	     if(cotizacion.Datos_facturacion__r.size() >0)
		               	     {
		               	     	for (Integer i = 0; cotizacion.Datos_facturacion__r.size()>i ; i++ )
		               	     	{
		               	     		cotizacion.Datos_facturacion__r.get(i).Blocked_BillingData__c= true;
		               	     	}
		               	     }
		               	     //-------------------------------------------------------------------------------------------------------
	                   	     */
	                   	     
	                   	     
	                   	     //*****Si el chequeo automático fue aprobado  crea la solicitud******************************
	                   	     Requestfinancial__c checfin = new Requestfinancial__c();
	                   	     if(!requestFromsimulation)
	                   	     
	                   	         //JAAR 21-03-2014 Validar si el chequeo de creditó esta apagado para controlar que todas las solictiudesp asen por cartera 
		                   	     if(response.indicador == false || (response.indicador == true && ChequeoApagado == true ) )
		                   	     {
		                   	     	// 2- llena el historial de Solicitudes a financiero  
			                   	     //Cambios si entra a facturación PENDIENTE
	                   	             oppcheck.StageName 					= '05 Cerrada Entregada Facturación';
			                   	     checfin.CreditCheckCode__c 			= response.checkingDescription;
			                   	     checfin.CreditLimitValidUntilDate__c	= response.riskClass.validityPeriod.endDate;
			                   	     checfin.IsCreditAnalysisRequired__c	= response.RequiereEstudio;
			                   	     checfin.IsCreditExceptionAllowed__c	= response.permiteExcepcion;
			                   	     checfin.LastCreditCheck__c            	= system.now();
			                   	     checfin.Idoportunity__c 				= IdOportunity;
			                   	     checfin.Chequeo_vigente__c				= true;
			                   	     checfin.Fecha_Entregada_Facturacion__c = system.now();
			                   	     system.debug('relacion_quotes  '+oppcheck.Quotes);
			                   	     checfin.Monto__c						= oppcheck.Quotes.get(0).GrandTotal;
			                   	     checfin.Status_del_chequeo__c			= 'EN PROCESO';
			                   	     if(response.permiteExcepcion && response.RequiereEstudio)
			                   	     {
			                   	     	checfin.Tipo_de_solicitud__c			= 'Excepción';
			                   	     }else if (response.permiteExcepcion && !response.RequiereEstudio)
			                   	     {
			                   	       checfin.Tipo_de_solicitud__c			= 'Excepción';
			                   	     }else if(!response.permiteExcepcion && response.RequiereEstudio)
			                   	     {
			                   	     	checfin.Tipo_de_solicitud__c			= 'Estudio de crédito';
			                   	     }else
			                   	     {
			                   	     	checfin.Tipo_de_solicitud__c			= '';
			                   	     }
			                   	     
			                   	     
			                   	     
			                   	     checfin.Mensajes_Chequeo__c			='';		
			                   	     for (CL008_Sap_ConsCupoCredit_ObjectsSF.DescripcionMsgRs msg: response.listCheckingDescription)
			                   	     {
			                   	     	checfin.Mensajes_Chequeo__c = checfin.Mensajes_Chequeo__c + '\n '+ msg.mensaje;	
			                   	     }
			                   	   
			                   	     Reqfinancial = getRequestfinancial(IdOportunity, checfin.CreditCheckCode__c );
			                   	     if(Reqfinancial <> null)
			                   	     {
			                   	     	for (Requestfinancial__c rf:Reqfinancial)
				                   	     {
				                   	     	rf.Chequeo_vigente__c = false;
				                   	     }
			                   	     }
			                   	     
			                   	     
			                   	     if(response.RequiereEstudio || response.permiteExcepcion)
		                       	     {
		                       	     	oppcheck.automaticresult__c			= 'Requiere verificación de Cartera';
		                       	     	checfin.automaticresult__c			= 'Requiere verificación de Cartera';
		                       	     	oppcheck.Semaforostatus__c			= 'Yellow';
		                       	     }else
		                       	     {
		                       	     	if(ChequeoApagado == true)
		                       	     	{
		                       	     		//JAAR 21-03-2014 Validar si el chequeo de creditó esta apagado para controlar que todas las solictiudesp asen por cartera 
		                       	     		oppcheck.automaticresult__c			= 'APROBADO - CHEQUEO AUTOMATICO-OFF';
		                       	     	    checfin.automaticresult__c			= 'APROBADO - CHEQUEO AUTOMATICO-OFF';
		                       	     	    oppcheck.Semaforostatus__c			= 'Yellow';
		                       	     	}else
		                       	     	{
		                       	     		oppcheck.automaticresult__c			= 'Rechazado no superó la validación inicial';
		                       	     	    checfin.automaticresult__c			= 'Rechazado no superó la validación inicial';
		                       	     	    oppcheck.Semaforostatus__c			= 'Red';
		                       	     	}
		                       	     	
		                       	     }
		                       	        oppcheck.endcheckup__c				= '';
		                   	     }else if(response.indicador == true &&  ChequeoApagado == false )
		                   	     {
		                   	     	
		                   	     	
		                   	     	//JAAR si el chequeo automatico fue aprobado ingresa directo a fulfillment
		                   	     	oppcheck.StageName 					= '06 Cerrada Entregada Fulfillment';
		                   	     	oppcheck.Fecha_Entregada_Fulfillment__c	=system.now();
		                   	     	//JAAR no pasa por facturación la fecha de entrada y salida es la misma
		                   	     	oppcheck.Fecha_Entregada_Facturacion__c			 	= system.now();
            						oppcheck.Fecha_cerrada_entregada_facturacion__c		= System.now();
            						checfin.Fecha_Entregada_Facturacion__c  			= system.now();
            						checfin.Date_of_Approval__c				    		= system.now();
            						
		                   	     	oppcheck.Fecha_cerrada_fulfillment__c		=null;
		        	             	oppcheck.automaticresult__c			= 'APROBADO';
		        	             	oppcheck.endcheckup__c				= 'APROBADO';
		        	             	oppcheck.Semaforostatus__c			= 'Green';
		        	             	
		        	             	//------CHEQUEO APROBADO---------------------------------------------------------
		        	                 checfin.CreditCheckCode__c 			= response.checkingDescription;
			                   	     checfin.CreditLimitValidUntilDate__c	= response.riskClass.validityPeriod.endDate;
			                   	     checfin.IsCreditAnalysisRequired__c	= response.RequiereEstudio;
			                   	     checfin.IsCreditExceptionAllowed__c	= response.permiteExcepcion;
			                   	     checfin.LastCreditCheck__c            	= system.now();
			                   	     checfin.Idoportunity__c 				= IdOportunity;
			                   	     checfin.Chequeo_vigente__c				= true;
			                   	     system.debug('relacion_quotes  '+oppcheck.Quotes);
			                   	     checfin.Monto__c						= oppcheck.Quotes.get(0).GrandTotal;
			                   	     checfin.Status_del_chequeo__c			= 'APROBADO';
			                   	     checfin.automaticresult__c				= 'APROBADO';
			                   	     checfin.User_approver__c				= 'SISTEMA';
			                   	     if(response.permiteExcepcion && response.RequiereEstudio)
			                   	     {
			                   	     	checfin.Tipo_de_solicitud__c			= 'Excepción';
			                   	     }else if (response.permiteExcepcion && !response.RequiereEstudio)
			                   	     {
			                   	       checfin.Tipo_de_solicitud__c			= 'Excepción';
			                   	     }else if(!response.permiteExcepcion && response.RequiereEstudio)
			                   	     {
			                   	     	checfin.Tipo_de_solicitud__c			= 'Estudio de crédito';
			                   	     }else
			                   	     {
			                   	     	checfin.Tipo_de_solicitud__c			= '';
			                   	     }
			                   	     
			                   	     
			                   	     
			                   	     checfin.Mensajes_Chequeo__c			='';		
			                   	     for (CL008_Sap_ConsCupoCredit_ObjectsSF.DescripcionMsgRs msg: response.listCheckingDescription)
			                   	     {
			                   	     	checfin.Mensajes_Chequeo__c = checfin.Mensajes_Chequeo__c + '\n '+ msg.mensaje;	
			                   	     }
			                   	   
			                   	     Reqfinancial = getRequestfinancial(IdOportunity, checfin.CreditCheckCode__c );
			                   	     if(Reqfinancial <> null)
			                   	     {
			                   	     	for (Requestfinancial__c rf:Reqfinancial)
				                   	     {
				                   	     	rf.Chequeo_vigente__c = false;
				                   	     }
			                   	     }
			                   	     
		        	             	//-------------------------------------------------------------------------------
		        	             	
		                   	     }
		                   	     
		                   	    /* 
		                   	     if (response.indicador == true )
		        	             {
		        	             	checfin.automaticresult__c			= 'APROBADO';
		        	             	oppcheck.automaticresult__c			= 'APROBADO';
		        	             	oppcheck.Semaforostatus__c			= 'Green';
		        	             }else
		        	             {
		        	             	 if(response.RequiereEstudio || response.permiteExcepcion)
		                       	     {
		                       	     	oppcheck.automaticresult__c			= 'Requiere verificación de Cartera';
		                       	     	checfin.automaticresult__c			= 'Requiere verificación de Cartera';
		                       	     	oppcheck.Semaforostatus__c			= 'Yellow';
		                       	     }else
		                       	     {
		                       	     	oppcheck.automaticresult__c			= 'Rechazado no superó la validación inicial';
		                       	     	checfin.automaticresult__c			= 'Rechazado no superó la validación inicial';
		                       	     	oppcheck.Semaforostatus__c			= 'Red';
		                       	     }
		        	             }
		                   	    */ 
		                   	     
		                   	     try{
		                   	     	    update oppcheck;
		                   	     	    if(Reqfinancial <> null)
		                   	     	    {
		                   	     	      update Reqfinancial;
		                   	     	    }
		                   	     	    
		                   	     	    insert checfin;	
		                   	     	    /* JAAR se guarda siemrpe el historial
		                   	     	    if(response.indicador == false)
		                   	     	    {
		                   	     	      insert checfin;	
		                   	     	    }
		                   	     	    */
		                   	     	    if(cotizacion.Datos_facturacion__r.size() >0)
			               	            {
			               	            	update cotizacion.Datos_facturacion__r;
			               	            }
		                   	     }catch(system.exception e)
		                   	     {
		                   	     	system.debug('No fue posible actualizar la opp  '+e);
		                   	     }
		                   	  
		           			   }
	                		
	                			   
	                	}
		                	
	                }
             } 
                //-------------------------JAAR 04-02-2014 MODIFICACION PARA LA PAGE------------------------------------
                resultDetalle = new  List<CL008_Sap_ConsCupoCredit_ObjectsSF.CreditWorthiness>();
                     Integer indicador=0;
                     String indicadorStr='';
                     if(mapRsChequearCred == null) return null;
                     for(CL008_Sap_ConsCupoCredit_ObjectsSF.ResponseChequearCreditos i:mapRsChequearCred.values()) {
                        indicadorStr=String.valueOf(indicador+1);
                        system.debug('indicador '+ indicadorStr + 'selection'+selection+ 'generando_resultDetalle_para la paginaVF  ' +resultDetalle);
                       
                            resultDetalle.add(i.parCreditWorthiness);                   
                       
                        indicador++;
                     }
                     system.debug('\n\n JAAR_resultDetalle  '+ resultDetalle);
                //--------------------------------------------------------------------------------------------------------
            }else
            {
                this.setMsg(0, 'Para realizar el chequeo de credito la cotización debe tener datos de facturación y la cuenta debe tener codigo de cliente unico');
                system.debug('\n\n El_documento_no_esta_completo no es posible continuar');   
            }
      // }else
      //{
             
      //}
     return null;   
    }
      /*******************************************************************************************************************    
    * JAAR 19-03-2014 Metodo que bloquea la oportunidad y sus relacionados 
        1. ingresa solo si da clic en el boton enviar aprobacion y se ejecuta el proceso
    * @return  boolean.  
    *********************************************************************************************************************/ 
     public boolean Block_data()
   {
   	 boolean exito = false;
   	 
   	  //1 - Bloquear el dato de facturación posterior al envio del chequeo ----------------------------------
   	     if(cotizacion.Datos_facturacion__r.size() >0)
   	     {
   	     	for (Integer i = 0; cotizacion.Datos_facturacion__r.size()>i ; i++ )
   	     	{
   	     		cotizacion.Datos_facturacion__r.get(i).Blocked_BillingData__c= true;
   	     	}
   	     }
   	     //-------------------------------------------------------------------------------------------------------
   	 
   	  //2 - Bloquea la oportunidad para que no pueda ser editada despues del chequeo
         oppcheck.blocked_opportunity__c        = true;
         RecordType recordtypeOp = [SELECT Id,Name FROM RecordType where Name = 'Oportunidad bloqueada'];
         oppcheck.RecordTypeId					= recordtypeOp.id;
         
      //3 - Bloquea la cotización
   	     RecordType recordtypecot = [SELECT Id,Name FROM RecordType where Name = 'Presupuesto Bloqueado'];
         cotizacion.blocked_quote__c = true;
         cotizacion.RecordTypeId     = recordtypecot.Id; 
         
         
   	 try{
   	 	 if(cotizacion.Datos_facturacion__r.size() >0)
   	         {
   	        	update cotizacion.Datos_facturacion__r;
   	        	update oppcheck;
   	        	update cotizacion;
   	        	exito = true;
   	         }
		}catch(system.exception e)
       	     {
       	     	system.debug('No fue posible actualizar la opp  '+e);
       	     }
   	 
   	 
   	 return exito;
   } 
    
    
    /*********************************************************************************************************************    
    * JAAR 17-03-2014 Valida que el texto del token online este de acuerdo a lo solicitado 
        1. Es un campo alfanumérico de 8 caracteres.
        2. Contiene números del 0 al 9 y letras de la A a la F.
    * @return  boolean.  
    *********************************************************************************************************************/ 
 public Boolean validaRTextTokenonline(String Tokenonline)
    {
        Boolean validation;
        String caracteres = 'abcdefABCDEF0123456789';
        if(Tokenonline.length()== 8)
         {
            for(Integer i=0;i<Tokenonline.length();i++)
            {
               if(caracteres.indexOf(Tokenonline.substring(i,i+1)) == -1)
               {
                 validation= false; 
                 system.debug('El_token_no_contiene_caracteres_especificados== '+ Tokenonline.substring(i,i+1)); 
               }else
               {
                 validation= true; 
                 
               }        
            } 
         }else
         {
            system.debug('El_token_contiene_menos_de_8_caracteres'+ Tokenonline); 
            validation=  false;
         }
         return validation;   
     }
    
    
    /**************** Action regresar button************/ 
      
    public PageReference Regresar(){ 
    	               
        PageReference pr = new  PageReference( '/'+Apexpages.currentPage().getParameters().get('PresupuestoId')  );         
        return pr;          
    }
    
    // 26-02-2014	JAAR Metodo que verifica si una cotización ya posee datos de facturacion y productos para poder invocar el chequeo de credito
    public Boolean ValidateCotizacion(Quote parQuote, boolean requestFromsimulation)
    {
        boolean Validate = false; 
        List<QuoteLineItem> prodbycotizacion =  [SELECT Id,LineNumber,ListPrice,Quantity,TotalPrice FROM QuoteLineItem 
                                                 WHERE QuoteId =: parQuote.id];
        
        List<Dato_facturacion__c> datosbycotizacion = [SELECT Fecha_primera_cuota__c,Id,Numero_cuotas__c,Presupuesto__c,Valor_facturacion__c FROM Dato_facturacion__c 
                                                       WHERE Presupuesto__c =: parQuote.id];
        if (prodbycotizacion <> null)
        {   
                system.debug('\n\n prodbycotizacion_diferente_de_null' + prodbycotizacion + ' para la cotizacion '+parQuote);   
            if(prodbycotizacion.size()>0)
            {
                system.debug('\n\n prodbycotizacion_size_mayor_a_cero');  
                //JAAR 25-02-2014 - Realizar la consulta del chequeo de crédito tenga o no un dato de facturación
                
                if(datosbycotizacion <> null)
                {
                    system.debug('\n\n tiene_datos_de_facturacion' + datosbycotizacion);  
                    if(datosbycotizacion.size() >0)
                    {
                        system.debug('\n\n tiene_datos_de_facturacion');  
                        Validate = true;
                        this.billingdata = true;
                    }else
	                {
	                	//26-02-2014	JAAR si es una SIMULACION de chequeo de credito no necesita obligatoriamente los datos
	                	this.billingdata  = false;
	                	if(requestFromsimulation == true)
	                	{
	                		 system.debug('\n\n No_tiene_datos_de_facturacion_pero_es_simulacion');  
	                         Validate = true;
	                	}
	                }
                }
                
            }
        }   
        
        return Validate;
    } 
    
    
     // aqui se debe tomar la lista de respuestas que esta a en SAP_CreditManagementClient           
    public List<CL008_Sap_ConsCupoCredit_ObjectsSF.CreditWorthiness> getRespuestasChequeCredito() {
         listResult = new List<CL008_Sap_ConsCupoCredit_ObjectsSF.CreditWorthiness>();
         
                             
               
             if(mapRsChequearCred == null) return null;
             system.debug('\n\n mapRsChequearCred======>' + mapRsChequearCred);
             for(CL008_Sap_ConsCupoCredit_ObjectsSF.ResponseChequearCreditos i:mapRsChequearCred.values()) {
                listResult.add(i.parCreditWorthiness);
             }
         system.debug('\n\nlistResult======>' + listResult);
          return listResult;
    }
    
    
    
    
    
     public void setMsg(integer typeMsg, String message){
        
        if(typeMsg ==null || typeMsg==0){
            Apexpages.Message msg = new Apexpages.Message(Apexpages.Severity.INFO,message);
            Apexpages.addMessage(msg);
        }
        
        if(typeMsg==1){
            Apexpages.Message msg = new Apexpages.Message(Apexpages.Severity.CONFIRM,message);
            Apexpages.addMessage(msg);
        }

        if(typeMsg==2){
            Apexpages.Message msg = new Apexpages.Message(Apexpages.Severity.ERROR,message);
            Apexpages.addMessage(msg);
        }
        
        return;
        
    } 
    
    /*******************************************************************************
    *                               QUERY AREA
    *******************************************************************************/    
     public Quote getQuoteById(String CotizacionId){
        List<Quote> Quot = [SELECT Ciudad_venta__c,GrandTotal,Id,Name,OpportunityId,Opportunity.Account.Codigo_cuenta__c,
                                Opportunity.Account.Codigo_cliente_unico__c,Opportunity.Account.Name,Opportunity.Account.Numero_identificacion__c,TotalPrice 
                                FROM Quote 
                                where Id =:CotizacionId];     
        if(Quot.size()>0){
            return Quot.get(0);      
        }else{      
            return null;
        }   
    }
    //Oportunity ----------------------------------------------------------
     public Opportunity getOpportunity(String IdOportunity){
        List<Opportunity> myopp = [SELECT CreditCheckCode__c,Amount,Token_venta_en_linea__c,blocked_opportunity__c,RecordTypeId,StageName,CreditLimitValidUntilDate__c,Id,automaticresult__c,Fecha_Entregada_Fulfillment__c,IsCreditAnalysisRequired__c,IsCreditChecked__c,
        								  IsCreditExceptionAllowed__c,Fecha_cerrada_entregada_facturacion__c,Comentarios_fulfillment__c,Responsable_fulfillmet__c,Semaforostatus__c,Status_fulfillment__c,Account.Pendiente_pago__c,
        								  fecha_devuelta_fulfillment__c,Fecha_cerrada_fulfillment__c,SyncedQuoteId,Estado_No_conformidad__c,Estado_No_conformidad_Cartera__c,Comentarios_Cartera__c 
        						   ,(SELECT GrandTotal,Id,IsSyncing,blocked_quote__c FROM Quotes WHERE IsSyncing = true)
        						  FROM Opportunity 
                                  where Id =:IdOportunity];     
        if(myopp.size()>0){
            return myopp.get(0);      
        }else{      
            return null;
        }   
    }
    
    //Solicitude de credito asociadas ----------------------------------------------------------
     public list<Requestfinancial__c> getRequestfinancial(String IdOportunity, String codecheck){
        List<Requestfinancial__c> Reqfin = [SELECT Chequeo_vigente__c,Id,Idoportunity__c,Fecha_Entregada_Facturacion__c,Date_of_Approval__c FROM Requestfinancial__c
                                   where Idoportunity__c =:IdOportunity AND CreditCheckCode__c !=: codecheck];     
        if(Reqfin.size()>0){
            return Reqfin;     
        }else{      
            return null;
        }   
    }
    
      public void disabledService(){
      	if(Test.isRunningTest()){
      		system.debug('disabledservice!!');
      		invoked = false;
      		lanzarProceso();
      	}
      }

}