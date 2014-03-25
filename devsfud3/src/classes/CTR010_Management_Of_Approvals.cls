/**                                                     
* ===================================================================================================================================
*  Desarrollado por:    Joe Alexander Ayala
*  Fecha:               Febrero 03 de 2014
*  Decripción:          Clase que controla la gestión de las aprobaciones
*  @version:            1.0
* ===================================================================================================================================
**/

public with sharing class CTR010_Management_Of_Approvals 
{
 public String strTittlePage {get;set;} //variable que contiene el título de la página visualforce
 
 public ApexPages.Standardcontroller controller;
 public boolean ApprovalCartera {get;set;}
 public boolean ApprovalFulfillment {get;set;}
 public String comentarios{get;set;}  
 public boolean allowedaccess {get;set;} 
 public Fulfillment_management__c gestionfull{get;set;} 
 public String idRequestfinancial {get;set;} 
 public String stroportunityid {get;set;} 
 public String strOperationCode {get;set;} 
 public String strorigin {get;set;}
 public String stroppName {get;set;}
 public String stroppowner {get;set;}
 public String profileuser{get;set;}
 public String userName{get;set;}
 public String userId{get;set;}
 public Quote cotizacion{ get; set; }
 public Opportunity oppcheck{ get; set; }
 public Profile strProfile{ get; set; }
 public Requestfinancial__c Reqfinancial{ get; set; } 
 
 public CTR010_Management_Of_Approvals()
 {
        if(Apexpages.currentPage().getParameters().get('OperationCode')!=null && Apexpages.currentPage().getParameters().get('OperationCode')=='CHEQUEO')
        {
                system.debug('\n\n Apexpages.currentPage_getParameters_requestFrom'+ Apexpages.currentPage().getParameters().get('oportunity'));  
                ApprovalCartera = true;
                ApprovalFulfillment = false;
                idRequestfinancial  = Apexpages.currentPage().getParameters().get('Requestfinaid');
        }else if(Apexpages.currentPage().getParameters().get('OperationCode')!=null && Apexpages.currentPage().getParameters().get('OperationCode')=='FULFILLMENT')
        {
                system.debug('\n\n APROBACION_FULFILLMENT');
                ApprovalFulfillment = true;
                ApprovalCartera = false;
                stroportunityid     = Apexpages.currentPage().getParameters().get('oportunity');
                gestionfull = createfullfillmentmanagement(stroportunityid);
        }
        profileuser = System.UserInfo.getProfileId();
        userName    = System.UserInfo.getName();
        userId          = System.Userinfo.getUserId();
        strProfile = getProfile(profileuser);
        system.debug('ESTE_ES_EL_PERFIL_ACTUAL '+profileuser);
        system.debug('ESTE_ES_EL_USUARIO_LOGUEADO_ACTUALMENTE '+userName);
        
        conf_Userapprover__c ConfPersUser = conf_Userapprover__c.getAll().get('CALLWS001_Chequeocredito');     
 }
 
 
 public PageReference lanzarProceso() 
 {
    this.controller  = controller;
     system.debug('idRequestfinancial '+ idRequestfinancial);          
     strOperationCode    = Apexpages.currentPage().getParameters().get('OperationCode');
     strorigin                   = Apexpages.currentPage().getParameters().get('origin');
     idRequestfinancial  = Apexpages.currentPage().getParameters().get('Requestfinaid');
     stroportunityid     = Apexpages.currentPage().getParameters().get('oportunity');
     oppcheck = getOpportunity(stroportunityid);
     Reqfinancial = getRequestfinancial(idRequestfinancial);
     //1- Datos de la oportunidad
     stroppName = oppcheck.Name;
     this.stroppowner = oppcheck.Owner.Name;
     //JAAR verificar si este perfil es permitido
     String permission = Validateprofile(oppcheck.StageName);
     system.debug('Tipo_depermiso_en_este_momento '+ permission);
     allowedaccess = allowedprofileaccess(strProfile.Name,permission,strOperationCode);
    
    
    
    
    return null;        
 }
 //metodo que crea temporalmente un objeto Fulfillment_management__c
 public Fulfillment_management__c createfullfillmentmanagement(String idportunity)
 {
        oppcheck = getOpportunity(stroportunityid);
        gestionfull = new Fulfillment_management__c();
        //gestionfull.Causes_of_return__c = '';
        gestionfull.Comments_fulfillment__c = '';
        gestionfull.Fecha_cerrada_fulfillment__c = system.now();
        gestionfull.Fecha_Entregada_Fulfillment__c= oppcheck.Fecha_Entregada_Fulfillment__c;
        gestionfull.IdOportunidad__c=idportunity;
        gestionfull.Responsable_fulfillment__c=userName;
        gestionfull.Status_fulfillment__c = '';
        
        
        return gestionfull;
        
 }
 
 //Metodo que verifica la etapa de la oportunidad para controlar el tipo de parobación que se requiere
 public String Validateprofile (String etapa)
 {
         String typepermission;
        if(etapa == '06 Cerrada Entregada Fulfillment')
        {
                typepermission = 'Aprobaciones fulfillment';
        }else if(etapa == '05 Cerrada Entregada Facturación')
        {
                typepermission = 'Aprobaciones de cartera';
        }else
        {
                typepermission = 'Sin permisos';
        }
        system.debug('tipo_de_permiso_requerido ' + typepermission);
        return typepermission;
 }
 
 /**************** Action aproval button************/   
 public PageReference doApproval(){  
            if(ApprovalCartera) 
            {
                Reqfinancial.Status_del_chequeo__c  ='APROBADO';
                Reqfinancial.User_approver__c       = userName;
                Reqfinancial.Date_of_Approval__c    = System.now();
                oppcheck.endcheckup__c              = 'APROBADO';
                oppcheck.Semaforostatus__c          = 'Green';
                oppcheck.StageName                  = '06 Cerrada Entregada Fulfillment';
                oppcheck.Fecha_Entregada_Fulfillment__c = system.now();
                //oppcheck.StageName                  = '09 Cerrada ganada';
                oppcheck.Fecha_cerrada_entregada_facturacion__c = System.now();
                oppcheck.Comentarios_Cartera__c         = Reqfinancial.Comentarios__c;
                
               
                
                
                if(allowedaccess)
                {
                        update  oppcheck; 
                        update  Reqfinancial;  
                        
                }else
                {
                        this.setMsg(0, 'Su perfil no dispone de los permisos necesarios para gestionar esta solicitud en la etapa actual del proceso ' );
                        return null;
                }
                     
            }else if(ApprovalFulfillment)
            {
                        gestionfull.Status_fulfillment__c               ='APROBADO';
                        gestionfull.Responsable_fulfillment__c  =userName;
                oppcheck.Fecha_cerrada_fulfillment__c   = system.now();
                oppcheck.Status_fulfillment__c                  ='APROBADO';
                oppcheck.Responsable_fulfillmet__c              = userId;
                oppcheck.StageName                                              = '09 Cerrada ganada';
                oppcheck.Comentarios_fulfillment__c     = gestionfull.Comments_fulfillment__c;
                
                
                
                if(allowedaccess)
                {
                        insert gestionfull;  
                        update  oppcheck; 
                }else
                {
                        this.setMsg(0, 'Su perfil no dispone de los permisos necesarios para gestionar esta solicitud en la etapa actual del proceso');
                        return null;
                }
            }  
                    
        PageReference pr = new  PageReference( '/'+stroportunityid );         
        return pr;          
    }
 
 /**************** Action reject button ************/   
 public PageReference doReject(){  
            if(ApprovalCartera) 
            {
                Reqfinancial.Status_del_chequeo__c ='RECHAZADO';
                Reqfinancial.User_approver__c      = userName;
                Reqfinancial.Date_of_Approval__c   = System.now();
                Reqfinancial.Estado_No_conformidad_Cartera__c = 'ABIERTA';
                oppcheck.endcheckup__c             = 'RECHAZADO';
                oppcheck.Semaforostatus__c         = 'Red';
                oppcheck.StageName                 = '07 Cerrada Devuelta Facturación';
                oppcheck.Fecha_cerrada_entregada_facturacion__c   = System.now(); 
                oppcheck.Fecha_devuelta_facturacion__c                    = System.now();       
                oppcheck.Comentarios_Cartera__c         = Reqfinancial.Comentarios__c;
                
                
                    if(allowedaccess)
                {
                        
                        update  oppcheck; 
                        update  Reqfinancial; 
                        Unlock_data(oppcheck.id);
                }else
                {
                        this.setMsg(0, 'Su perfil no dispone de los permisos necesarios para gestionar esta solicitud en la etapa actual del proceso');
                        return null;
                }  
            } else if(ApprovalFulfillment)
            {
                        gestionfull.Status_fulfillment__c               ='RECHAZADO';
                        gestionfull.Estado_No_conformidad__c    = 'ABIERTA';    
                        gestionfull.Responsable_fulfillment__c  =userName;
                oppcheck.Fecha_cerrada_fulfillment__c   = system.now();
                oppcheck.fecha_devuelta_fulfillment__c = system.now();
                oppcheck.Status_fulfillment__c                  ='RECHAZADO';
                oppcheck.Responsable_fulfillmet__c              = userId;
                oppcheck.StageName = '08 Cerrada Devuelta Fulfillment';
                oppcheck.Comentarios_fulfillment__c     = gestionfull.Comments_fulfillment__c; 
                
                //Limpiar  todos los campos del chequeo de cédito  
                
                //oppcheck.CreditCheckCode__c                           = '';
                
                
                        
                        
                
                if(allowedaccess)
                {
                        if(oppcheck.CreditCheckCode__c <>null )
                                {
                                        system.debug('oppcheck.CreditCheckCode_01 '+oppcheck.CreditCheckCode__c);
                                        Reqfinancial = getRequestfinancialxcodanalisis(oppcheck.CreditCheckCode__c);
                                        if(Reqfinancial <> null)
                                        {
                                                //JAAR 11-03-2014 Se define con Diana Melo que si una solicitud es rechazada por fullfilment el chequeo de credito se eliminará ya que no ha sido gestionado por cartera
                                                if(Reqfinancial.Status_del_chequeo__c == 'EN PROCESO')
                                                {
                                                        if(Reqfinancial.User_approver__c <> null || Reqfinancial.Fecha_Entregada_Facturacion__c <> null)
                                                        {
                                                                system.debug('chequeo_ya_procesado_por_cartera '+Reqfinancial); 
                                                        }else
                                                        {
                                                                system.debug('chequeo_no_procesado_por_cartera_se_eliminara======>>>>>  '+Reqfinancial); 
                                                                delete Reqfinancial;
                                                        }
                                                }
                                                
                                        
                                        }
                                        
                                }
                        update  oppcheck; 
                        insert gestionfull;  
                        Unlock_data(oppcheck.id);
                        
                }else
                {
                        this.setMsg(0, 'Su perfil no dispone de los permisos necesarios para gestionar esta solicitud en la etapa actual del proceso');
                        return null;
                }
            }   
                    
        PageReference pr = new  PageReference( '/'+stroportunityid );         
        return pr;          
    }
 
  
 /**************** Action cancel button************/     
    public PageReference doCancel(){
        PageReference pageref;
        if(ApprovalCartera && strorigin == 'Solicitudafinanciero') 
            {
                PageReference pr = new  PageReference( '/'+idRequestfinancial );         
                 pageref= pr; 
            } else if(ApprovalFulfillment && strorigin == 'Opportunity')
            {
                PageReference pr = new  PageReference( '/'+stroportunityid );         
                pageref= pr; 
            }               
        return pageref;         
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
     /*******************************************************************************************************************    
    * JAAR 19-03-2014 Metodo que desbloquea la oportunidad y sus relacionados 
        1. ingresa solo si se rechaza algun proceso de aprobacion
    * @return  boolean.  
    *********************************************************************************************************************/ 
   public boolean Unlock_data(String IdOportunity)
   {
         boolean exito = false;
         //realizo la busqueda de los datos de facturación asociados a la oportunidad
         cotizacion = [SELECT IsSyncing,Id,OpportunityId,RecordTypeId,blocked_quote__c,(SELECT Blocked_BillingData__c,Id FROM Datos_facturacion__r)  FROM Quote WHERE IsSyncing = true AND OpportunityId =: IdOportunity]; 
     //1 - Desbloquear el dato de facturación posterior al rechazo del proceso ----------------------------------
         if(cotizacion.Datos_facturacion__r.size() >0)
          {
             for (Integer i = 0; cotizacion.Datos_facturacion__r.size()>i ; i++ )
                {
                   cotizacion.Datos_facturacion__r.get(i).Blocked_BillingData__c= false;
                }
             exito = true;      
          }
          //2 - desbloquea la oportunidad para que no pueda ser editada despues del chequeo
           oppcheck.blocked_opportunity__c        = false;
           if (oppcheck.Unidad_de_Negocio__c <> null)
           {
                RecordType recordtypeOp = [SELECT Id,Name FROM RecordType where Name =: oppcheck.Unidad_de_Negocio__c];
        oppcheck.RecordTypeId                                   = recordtypeOp.id;
           }
           //3 - Desbloquea la cotización
           RecordType recordtypecot = [SELECT Id,Name FROM RecordType where Name = 'Presupuesto desbloqueado'];
           cotizacion.RecordTypeId = recordtypecot.Id;
           cotizacion.blocked_quote__c = false;
          try
          {
                if(cotizacion.Datos_facturacion__r.size() >0)
               {
                 update cotizacion.Datos_facturacion__r;
                 update cotizacion;
               }
               update oppcheck;
          }catch(system.exception e)
               {
                 system.debug('No fue posible actualizar la opp  '+e);
               }
          
             //-------------------------------------------------------------------------------------------------------
    return exito;
   } 
    /*************************************************************************************************************
    *                                            QUERY AREA
    *************************************************************************************************************/  
    //Oportunity --------------------------------------------------------------------------------
     public Opportunity getOpportunity(String IdOportunity){
        List<Opportunity> myopp = [SELECT Name,Owner.Name,endcheckup__c,Semaforostatus__c,CreditCheckCode__c,StageName,CreditLimitValidUntilDate__c,Id,automaticresult__c,Responsable_fulfillmet__c,
                                   Fecha_Entregada_Facturacion__c,Comentarios_fulfillment__c, IsCreditAnalysisRequired__c,IsCreditChecked__c,IsCreditExceptionAllowed__c,Fecha_Entregada_Fulfillment__c,
                                   Fecha_cerrada_entregada_facturacion__c,fecha_devuelta_fulfillment__c,blocked_opportunity__c,Unidad_de_Negocio__c,Fecha_devuelta_facturacion__c,Comentarios_Cartera__c 
                                                           ,(SELECT GrandTotal,Id,IsSyncing FROM Quotes WHERE IsSyncing = true)
                                                          FROM Opportunity 
                                  where Id =:IdOportunity];     
        if(myopp.size()>0){
            return myopp.get(0);      
        }else{      
            return null;
        }   
    }
    
      //Solicitude de credito asociadas ----------------------------------------------------------
     public Requestfinancial__c getRequestfinancial(String idfinancial){
        List<Requestfinancial__c> Reqfin = [SELECT automaticresult__c,Chequeo_vigente__c,Comentarios__c,User_approver__c,Date_of_Approval__c,CreditCheckCode__c,Id,Monto__c,Name,Status_del_chequeo__c,Tipo_de_solicitud__c 
                                                                                FROM Requestfinancial__c WHERE Id =:idfinancial];     
        if(Reqfin.size()>0){
            return Reqfin.get(0);
        }else{      
            return null;
        }   
    }
    
      //Solicitude de credito asociadas ----------------------------------------------------------
     public Requestfinancial__c getRequestfinancialxcodanalisis(String Codanalisis){
        List<Requestfinancial__c> Reqfin = [SELECT automaticresult__c,Chequeo_vigente__c,Comentarios__c,Fecha_Entregada_Facturacion__c,User_approver__c,Date_of_Approval__c,CreditCheckCode__c,Id,Monto__c,Name,Status_del_chequeo__c,Tipo_de_solicitud__c 
                                            FROM Requestfinancial__c WHERE CreditCheckCode__c =:Codanalisis];     
        if(Reqfin.size()>0){
            return Reqfin.get(0);
        }else{      
            return null;
        }   
    }
    
    
     //Validar usuario aprobador ----------------------------------------------------------
     public Profile getProfile(String idProfile){
        List<Profile> ReqProfile = [SELECT Id,Name FROM Profile WHERE Id =:idProfile];     
        if(ReqProfile.size()>0){
            return ReqProfile.get(0);
        }else{      
            return null;
        }   
    }
    
    /******************Administración de Permisos***********************************************/
        public boolean allowedprofileaccess(String idProfile, String typeofpermission,String strOperationCode){
                system.debug('idProfile: '+idProfile + '  typeofpermission   '+typeofpermission + ' strOperationCode  ' + strOperationCode);
        List<conf_Userapprover__c>  allowed = [SELECT Funcion__c,Id,Name,Perfil__c,OperationCode__c  FROM conf_Userapprover__c 
                                                                                   WHERE Funcion__c =: typeofpermission 
                                                                                   AND Perfil__c =:idProfile 
                                                                                   AND OperationCode__c =:strOperationCode];
                system.debug('PERFIL_BUSCADO_TAMAÑO: '+allowed.size());
                if(allowed.size()>0){
                        system.debug('PERFIL_BUSCADO: '+allowed.get(0).Perfil__c);
                        return true;
                }
                return false;
        }       
    
    
    
     

    
     

}