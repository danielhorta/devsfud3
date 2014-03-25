/*
*   Create default quota distribution values
*   20 Enero 2014 - Joe Ayala - TG001_Quote_CreateDefaultQuota: call CreateQuotation class
*/

trigger TG004_Movimiento_produccion_ActualizationActivo on Movimiento_produccion__c (after update) {

    
     set<Id> mov_prod = new Set<Id>();
  // Set<Id> synquedQuote = new Set<Id>();
  for (Movimiento_produccion__c oMovprod : Trigger.new){ 
  	mov_prod.add(oMovprod.Id);
  }
    
  integer size = mov_prod.size();
  system.debug('JDDEBUG2: size: '+size);
  
   if(size==1){
 
 Movimiento_produccion__c[] movprodOld = 
        [select id 
        		,Etapa__c
        		,Activo__c
                from Movimiento_produccion__c 
         where id in :mov_prod];
         

  //Asset[] oAssets = Trigger.new;
    
    CL002_AssetsProcessing.UpsertStatus(movprodOld);
 }
    
   
    
    
}