/*
*   Calculate Life time after asset is updated
*   13 Enero 2013 - Jairo Guzman - TG003_Asset_UpdateLifeTime: call AssetsLifeTime class
*/

trigger TG003_Asset_UpdateLifeTime on Asset (after update) {
  

  Set<Id> AssetId = new Set<Id>();
 
  for (Asset oAsset : Trigger.new){ 
  		
        AssetID.add(oAsset.Id);
        system.debug('JDDEBUG2: entries: '+AssetID);
   
  }
  
  integer size = AssetId.size();
  system.debug('JDDEBUG2: size: '+size);
 
 if(size==1){
 
 Asset[] entries = 
        [select id, 
        		status, 
        		product2Id, 
        		InstallDate,
                UsageEndDate,
                Activo_relacionado__c,
                Fecha_primera_activacion__c,
                Fecha_vencimiento_anterior__c
                from Asset 
         where id in :AssetId];
         

  //Asset[] oAssets = Trigger.new;
    
    CL002_AssetsProcessing.AssetsLifeTime(entries);
 }
}