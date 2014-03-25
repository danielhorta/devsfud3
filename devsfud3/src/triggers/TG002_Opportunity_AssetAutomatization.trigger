/*
*   Automatization over Assets when opportunity is won
*   10 Enero 2013 - Jairo Guzman - TG002_Opportunity_AssetAutomatization: call CL002_AssetsProcessing class
*  @version:            1.0*   
*  @version:            1.1* JAAR 06-03-2014 se depreca actualización del campo Fecha_cerrada_fulfillment__c ya que se reemplaza en el nuevo flujo 
*  @version:            1.2* JAAR 11-03-2014 por cambio en el orden de los flujos se modifica la etapa en la que se actualiza la Fecha inicial cerrada entregada al momento en que cambia a 06 Cerrada Entregada Fulfillment
*/

trigger TG002_Opportunity_AssetAutomatization on Opportunity (after update) {

   // Opportunity[] oOpportunity = Trigger.new;
   // Set<Id> AssetId = new Set<Id>();
  set<Id> opp = new Set<Id>();
  // Set<Id> synquedQuote = new Set<Id>();
  for (Opportunity oOpp : Trigger.new){ 
        
        opp.add(oOpp.Id);
       
        system.debug('JDDEBUG2: entries: '+opp);
       // system.debug('JDDEBUG2: entries: '+synquedQuote);
     
  }
  
    integer size = opp.size();
  system.debug('JDDEBUG2: size: '+size);
 
  system.debug('JDDEBUG2: trigger.opp: '+Trigger.new);
 if(size==1){
 
 Opportunity[] oOpportunity = 
        [select id, 
                SyncedQuoteId,
                IsWon,
                IsClosed,
                AccountId,
                Ano_Fiscal__c,
                Ciudad_venta__c
                ,StageName
                ,Fecha_cerrada_entregada_facturacion__c
                ,Fecha_inicial_cerrada_entregada__c
                ,Fecha_cerrada_fulfillment__c
                ,Fecha_cerrada_ganada__c
                from Opportunity 
         where id in :opp];
  
  	AggregateResult[] qrAux;
  
	for(Opportunity op :oOpportunity){
		
		if(op.IsWon){
			 
				  	system.debug('qraux: '+qrAux);
				  	
				  	if(Test.isRunningTest())
				  	{
				  		 qrAux = [SELECT count(Id) Max_Codigo_activo__c FROM Extension_archivo__c ];//
				  	}else
				  	if(qrAux == null)
				  	{	
				  		 qrAux = [select MAX(Codigo_activo__c) Max_Codigo_activo__c from asset]; //JDHC 20 febrero 2014 se saca esta asignacion del metodo calcnewasset debido a que se ejecutava varias veces y generaba los 50001 rows 
				    }
		
		}	
		
		if(op.StageName == '06 Cerrada Entregada Fulfillment'){ //JAAR 11-03-2014 por cambio en el orden de los flujos se modifica la etapa de esta linea de codigo a 06 Cerrada Entregada Fulfillment
				system.debug('JDDEBUGop: stage: '+op.StageName);
				system.debug('JDDEBUGop: fecha: '+op.Fecha_cerrada_entregada_facturacion__c);
				if(op.Fecha_inicial_cerrada_entregada__c == null){
					Opportunity op1 = new Opportunity();
					op1.Id = op.id;
					op1.Fecha_inicial_cerrada_entregada__c = datetime.now();
					system.debug('JDDEBUGop: fecha1: '+op1.Fecha_cerrada_entregada_facturacion__c);
					update op1;
				}			
		}
		if(op.StageName == '05 Cerrada Entregada Facturación'){ 
				system.debug('JDDEBUGop: stage: '+op.StageName);
				system.debug('JDDEBUGop: fecha: '+op.Fecha_cerrada_entregada_facturacion__c);
				if(op.Fecha_inicial_cerrada_entregada__c == null){
					Opportunity op1 = new Opportunity();
					op1.Id = op.id;
					op1.Fecha_inicial_cerrada_entregada__c = datetime.now();
					system.debug('JDDEBUGop: fecha1: '+op1.Fecha_cerrada_entregada_facturacion__c);
					update op1;
				}			
		}
		
		
		
		
		if(op.StageName == '09 Cerrada ganada'){
			if(op.Fecha_cerrada_ganada__c == null){
			Opportunity op2 = new Opportunity();
					op2.Id = op.id;
					op2.Fecha_cerrada_ganada__c = datetime.now();
					//system.debug('JDDEBUGop: fecha1: '+op1.Fecha_cerrada_entregada_facturacion__c);
					update op2;
			}
		}
		/*
		if(op.StageName == '06 Cerrada Entregada Fulfillment'){
			Opportunity op3 = new Opportunity();
			if(op.Fecha_cerrada_fulfillment__c == null){
					//op3.Id = op.id;
					//op3.Fecha_cerrada_fulfillment__c = datetime.now();JAAR 06-03-2014 se depreca esta actualización ya que se reemplaza en el nuevo flujo 
					//system.debug('JDDEBUGop: fecha1: '+op1.Fecha_cerrada_entregada_facturacion__c);
					update op3;
			}
		}
	   */		
	}
  //Asset[] oAssets = Trigger.new;
    system.debug('jddebugopp: tgold: '+Trigger.old);
   CL002_AssetsProcessing.CreateAssets(oOpportunity,qrAux,Trigger.old);
 }
    
    //CL002_AssetsProcessing.CreateAssets(oOpportunity);
}