/**                                                     
* ===================================================================================================================================
*  Desarrollado por:    Joe Alexander Ayala
*  Fecha:               Marzo 10 de 2013
*  Decripción:          Trigger generado en las tareas de no conformidad para actualizar el campo Estado No conformidad  en la oportunidad 
*  @version:            1.0

* ===================================================================================================================================
**/


trigger TG008_Task_updateStateNoconformidad on Task (after update) {

 if(Trigger.isAfter && Trigger.old.size()==1 ){
 	
 	Task objOld = Trigger.old[0];
 	Task objnew = Trigger.new[0];
 	system.debug('mitarea  ' + objOld);
 	if(objOld.Subject == 'No Conformidad FulFillment' && objnew.Status == '03. Completada' && objOld.WhatId <> null)
 	{
	 	system.debug('entro_mitarea  ' + objOld);
	 	//Task[] Tasknoconformidad = [SELECT AccountId,Comentarios_Asesor__c,Id,OwnerId,Status,Subject,Whatid FROM Task WHERE Id =: objOld.id];
        Fulfillment_management__c Fm =[SELECT Id,IdOportunidad__c,Estado_No_conformidad__c FROM Fulfillment_management__c WHERE id =:objOld.WhatId];
        Opportunity opp = [SELECT Estado_No_conformidad__c,Id,Status_fulfillment__c FROM Opportunity WHERE id =:Fm.IdOportunidad__c ];
        try{
        	Fm.Estado_No_conformidad__c = 'CERRADA';
        	opp.Estado_No_conformidad__c = 'CERRADA';
        	system.debug('modifico_la_opp   ' + opp +'y_la_gestionfull  ' +Fm);
        	update opp;
        	update Fm;
        	system.debug('modifico_la_gestionfull  ' +Fm);
        }catch(system.exception e){
        	
        }
    
    }else if(objOld.Subject == 'No Conformidad FulFillment' && (objnew.Status == '04. En espera de alguien mas' ||objnew.Status == '05. Aplazado' ) && objOld.WhatId <> null)
 	{
 		system.debug('entro_mitarea_en_proceso  ' + objOld);
        Fulfillment_management__c Fm =[SELECT Id,IdOportunidad__c,Estado_No_conformidad__c FROM Fulfillment_management__c WHERE id =:objOld.WhatId];
        Opportunity opp = [SELECT Estado_No_conformidad__c,Id,Status_fulfillment__c FROM Opportunity WHERE id =:Fm.IdOportunidad__c ];
        try{
        	Fm.Estado_No_conformidad__c = 'EN PROCESO';
        	opp.Estado_No_conformidad__c = 'EN PROCESO';
        	system.debug('modifico_la_opp   ' + opp +'y_la_gestionfull  ' +Fm);
        	update opp;
        	update Fm;
        	system.debug('modifico_la_gestionfull_en_proceso  ' +Fm);
        }catch(system.exception e){
        	
        }
 	}else if(objOld.Subject == 'No Conformidad Cartera' && objnew.Status == '03. Completada' && objOld.WhatId <> null)
 	{
	 	system.debug('entro_mitarea_facturacion  ' + objOld);
        Requestfinancial__c Fm =[SELECT Estado_No_conformidad_Cartera__c,Id,Idoportunity__c FROM Requestfinancial__c WHERE id =:objOld.WhatId];
        Opportunity opp = [SELECT Estado_No_conformidad_Cartera__c ,Id,endcheckup__c FROM Opportunity WHERE id =:Fm.Idoportunity__c ];
        try{
        	Fm.Estado_No_conformidad_Cartera__c  = 'CERRADA';
        	opp.Estado_No_conformidad_Cartera__c = 'CERRADA';
        	system.debug('modifico_la_opp   ' + opp +'y_la_solicfinanciero  ' +Fm);
        	update opp;
        	update Fm;
        	system.debug('modifico_la_solicitudfinaciera  ' +Fm);
        }catch(system.exception e){
        	
        }
    
    }else if(objOld.Subject == 'No Conformidad Cartera' && (objnew.Status == '04. En espera de alguien mas' ||objnew.Status == '05. Aplazado' ) && objOld.WhatId <> null)
 	{
	 	system.debug('entro_mitarea_facturacion  ' + objOld);
        Requestfinancial__c Fm =[SELECT Estado_No_conformidad_Cartera__c,Id,Idoportunity__c FROM Requestfinancial__c WHERE id =:objOld.WhatId];
        Opportunity opp = [SELECT Estado_No_conformidad_Cartera__c ,Id,endcheckup__c FROM Opportunity WHERE id =:Fm.Idoportunity__c ];
        try{
        	Fm.Estado_No_conformidad_Cartera__c  = 'EN PROCESO';
        	opp.Estado_No_conformidad_Cartera__c = 'EN PROCESO';
        	system.debug('modifico_la_opp   ' + opp +'y_la_solicfinanciero  ' +Fm);
        	update opp;
        	update Fm;
        	system.debug('modifico_la_solicitudfinaciera  ' +Fm);
        }catch(system.exception e){
        	
        }
    
    }
 	
 }
 


}