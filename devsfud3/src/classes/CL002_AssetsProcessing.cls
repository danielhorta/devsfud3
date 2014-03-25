/*
*  Assets automatization 
*  09 Enero 2014 - Jairo Guzman - CreateAssets: based on opportunity-quote create assets 
*  12 Enero 2014 - Jairo Guzman - UpsertAssets: insert or update assets when opportunity is won
*  12 Enero 2014 - Jairo Guzman - CancelAssets: cancel assets when opportunity is lose
*  24 Enero 2014 - Jairo Guzman - Update validation rules over assets
*  JDHC 20 febrero 2014 - Juan Daniel Horta - Solucion de  error de 50001 rows
*  JDHC 21 febrero 2014 - Juan Daniel Horta - activos de upselling con el mismo codigo de activo del target
*/
public class CL002_AssetsProcessing{
    
    /***************UPDATE OPPORTUNITY ASSET MOV ************************************/
    
	/*based on opportunity-quote create assets*/
    public static void CreateAssets(Opportunity [] oOpportunities, AggregateResult[] qrAux,Opportunity [] oOppOld ) {
  	
    system.debug('qraux: '+qrAux);
    for (Opportunity op :oOpportunities){
       		for(Opportunity opOld : oOppOld){
            if(op.IsWon && opOld.Fecha_cerrada_ganada__c == null){

				//validate quote status
				CL005_QuoteProcessing Valq = new CL005_QuoteProcessing(op.SyncedQuoteId);
				if(Valq.ValidateQuoteRules()){
					//get quote item to create assets
	                QuoteLineItem[] oQuoteItems = 
	                    [select id
	                         	,LineNumber
	                         	,TotalPrice
	                         	,Activo_producido__c
	                         	,Activo_renovacion__c
	                         	,Token_publicidad__c
	                         	,Tipo_venta__c
	                         	
	                         	,PricebookEntry.Product2.Id
	                         	,PricebookEntry.Product2.ProductCode
	                         	,PricebookEntry.Product2.Genera_Produccion__c
	                         	,PricebookEntry.Product2.Linea_de_negocio__c
	                         	,PricebookEntry.Product2.Linea_de_produccion__c
	                         	,PricebookEntry.Product2.Tipo_de_produccion__c
	                         	
	                         	,Activo_producido__r.id
	                         	,Activo_producido__r.Name
	                         	,Activo_producido__r.AccountId
	                         	,Activo_producido__r.ContactId
	                         	,Activo_producido__r.Price
	                         	,Activo_producido__r.Product2Id
	                         	,Activo_producido__r.PurchaseDate
	                         	,Activo_producido__r.SerialNumber
	                         	,Activo_producido__r.Status
	                         	,Activo_producido__r.Activo_relacionado__c
	                         	,Activo_producido__r.Ano_Fiscal__c
	                         	,Activo_producido__r.Codigo_activo__c
	                         	,Activo_producido__r.Codigo_internet__c
	                         	,Activo_producido__r.Fecha_primera_activacion__c
	                         	,Activo_producido__r.Fecha_vencimiento_anterior__c
	                         	,Activo_producido__r.Localidad_venta__c
	                         	,Activo_producido__r.Responsable_del_activo__c
	                         	
	                         	,Activo_Upselling__c
	                         	
	                         	,Quote.Opportunity.Numero_contrato__c
	                         	
	                     from 	QuoteLineItem 
	                     where 	Quantity = 1
	                     		and PricebookEntry.Product2.Id != null
	                       		and QuoteId =: op.SyncedQuoteId];
                
                	for (QuoteLineItem qi :oQuoteItems){
	                    //create or update assets
	                    UpsertAssets(op,qi,qrAux );
                	}									
				}
				else{
					string strThrow = '';
					for(ApexPages.Message errms:Valq.ErrorList){
						System.debug('ValidateQuoteRulesError::' + errms);
						strThrow = strThrow + errms;
					}
					
					throw new CL002_AssetsProcessing_Exception(strThrow);
					
				}
            }
            else if(op.IsClosed && op.IsWon == false){
                
                //get quote item to cancel assets
                QuoteLineItem[] oQuoteItems = 
                    [select	id
                         	,PricebookEntryId
                         	,LineNumber
                         	,TotalPrice
                         	,Activo_producido__c
                         	,Activo_renovacion__c
                         	,Token_publicidad__c
                         	
                         	,Activo_producido__r.id
                         	,Activo_producido__r.Name
                         	,Activo_producido__r.Status

                     from 	QuoteLineItem 
                     where 	Quantity = 1
                     		and QuoteId =: op.SyncedQuoteId];
                     		
                     set<Id> qli = new Set<Id>();
					  // Set<Id> synquedQuote = new Set<Id>();
					  for (QuoteLineItem oqli : oQuoteItems){ 
					        
					        qli.add(oqli.Activo_producido__c);
					       
					        system.debug('JDDEBUG2: entries: '+oqli);
					       // system.debug('JDDEBUG2: entries: '+synquedQuote);
					     
					  }
					  
					 
					  
					  	Movimiento_produccion__c[] RelProdMov =
	      		[select	id
	                 	,Name
	                 	,Etapa__c
	                 	,Activo__c
	             from 	Movimiento_produccion__c
	             where 	Activo__c =: qli];
					  
				
				
				for(QuoteLineItem qi :oQuoteItems){	               
                	for (Movimiento_produccion__c rpm :RelProdMov){
                 //cancel related assets
	                 	if(qi.Activo_producido__c == rpm.Activo__c){
	                 		CancelAssets(op,qi,rpm);	
	                 	}
                    
                	}
                }
            }
       		}
          	System.debug('\n\n****Cantidad_de_Queries_consumidos_por_este_proceso: ' + Limits.getQueries());
        }
  	}
  
	/*Create assets*/
    private static void UpsertAssets(Opportunity op, QuoteLineItem qi, AggregateResult[] qrAux ){

    	//validate insert or update operation
        Boolean InsertRegister = (qi.Activo_producido__c == null);
         
        //New Assets   
        Asset RelatedAsset = new Asset();
            
        if(!InsertRegister){
        	//update related asset
        	RelatedAsset = qi.Activo_producido__r; 
      	}
      	
      	string strAssetName = System.now().format('YYYY')
                         + '_' + CL000_Utils.GetMonthName(System.now()) 
                         + '_' + qi.PricebookEntry.Product2.ProductCode 
                         + '_' + string.valueof(qi.Quote.Opportunity.Numero_contrato__c);
      	
        if(qi.Activo_renovacion__c == null){
          
  			//////new sale//////
            
            strAssetName = strAssetName + '_VN';
            if(strAssetName.length() > 75){
            	strAssetName = strAssetName.substring(0, 75);
            }
            
            
            //create asset
            RelatedAsset.AccountId = op.AccountId;
            RelatedAsset.IsCompetitorProduct = false;
            RelatedAsset.Name = strAssetName;
	       	RelatedAsset.Price = qi.TotalPrice;
	       	RelatedAsset.Product2Id = qi.PricebookEntry.Product2.id;
	       	RelatedAsset.PurchaseDate = System.Today();
	       	RelatedAsset.Quantity = 1;
	       	RelatedAsset.Status = CL000_Utils.C_NewAssetStatus;
	       	RelatedAsset.Ano_Fiscal__c = op.Ano_Fiscal__c;
	       	if(qi.Activo_Upselling__c != null){	//JDHC 21 febrero 2014 se agrega condicion para evaluar si es activo de upselling en cuyo caso se deja el mismo codigo de activo del activo relacionado
	       		 Asset[] OldAsset = 
            	[select id  
            			,Codigo_activo__c
            	 from   asset
                 where id =: qi.Activo_Upselling__c];
             	RelatedAsset.Codigo_activo__c = OldAsset[0].Codigo_activo__c;		
	       	}else{
	       		RelatedAsset.Codigo_activo__c = CalcNewAssetCode(RelatedAsset,qrAux );
	       	}
	  	   	RelatedAsset.Localidad_venta__c = op.Ciudad_venta__c; //JAAR 23-01-2014 Se agrega modificacion para sincronizar la cudad de venta de la opp al activo
	  	   	RelatedAsset.Activo_Upselling__c = qi.Activo_Upselling__c;
	  	   	RelatedAsset.Tipo_venta__c = qi.Tipo_venta__c; 
	  	   	RelatedAsset.Oportunidad_relacionada__c = op.Id;
	  	   	RelatedAsset.Partida_de_presupuesto__c = qi.Id;
		}
        else{
        	
        	//////renew sale//////
			              
            //get old assets
            Asset[] OldAsset = 
            	[select id
                     	,AccountId
                     	,ContactId
                     	,InstallDate
                     	,Name
                     	,Product2Id
                     	,SerialNumber
                     	,UsageEndDate
                     	,Codigo_activo__c
                     	,Codigo_internet__c
                     	,Fecha_primera_activacion__c
                     	,Localidad_venta__c //JAAR 23-01-2014 Se agrega modificacion para sincronizar la cudad de venta de la opp al activo 
                     	,Responsable_del_activo__c
                     	
                     	,Product2.ProductCode
                     	,Product2.Linea_de_produccion__c
                 from   asset
                 where id =: qi.Activo_renovacion__c];
                
        	if(OldAsset.size() == 1){

				//validate production line 
          		if(OldAsset[0].Product2.Linea_de_produccion__c == qi.PricebookEntry.Product2.Linea_de_produccion__c){
                    
					strAssetName = strAssetName + '_R';
		            if(strAssetName.length() > 75){
		            	strAssetName = strAssetName.substring(0, 75);
		            }                      
                    
        			RelatedAsset.AccountId = op.AccountId;
                	RelatedAsset.IsCompetitorProduct = false;
                	RelatedAsset.Name = strAssetName;
                	RelatedAsset.Price = qi.TotalPrice;
                	RelatedAsset.Product2Id = + qi.PricebookEntry.Product2.id;
	            	RelatedAsset.Quantity = 1;
	            	RelatedAsset.Status = CL000_Utils.C_NewAssetStatus;
				 	RelatedAsset.Activo_relacionado__c = OldAsset[0].id;
                 	RelatedAsset.Ano_Fiscal__c = op.Ano_Fiscal__c;
                    RelatedAsset.Codigo_activo__c = OldAsset[0].Codigo_activo__c;
                    RelatedAsset.Codigo_internet__c = OldAsset[0].Codigo_internet__c;
                    RelatedAsset.Fecha_primera_activacion__c = OldAsset[0].Fecha_primera_activacion__c;
                    RelatedAsset.Fecha_vencimiento_anterior__c = OldAsset[0].UsageEndDate;
                    RelatedAsset.Responsable_del_activo__c = OldAsset[0].Responsable_del_activo__c;
                    RelatedAsset.ContactId = OldAsset[0].ContactId;
                    RelatedAsset.PurchaseDate = System.Today();
                    RelatedAsset.SerialNumber = OldAsset[0].SerialNumber;
                    RelatedAsset.Localidad_venta__c = OldAsset[0].Localidad_venta__c;
                    RelatedAsset.Activo_Upselling__c = qi.Activo_Upselling__c;
                    RelatedAsset.Tipo_venta__c = qi.Tipo_venta__c;
                    RelatedAsset.Oportunidad_relacionada__c = op.Id;
                    RelatedAsset.Partida_de_presupuesto__c = qi.Id;
                }
            }
        }
			
  		//insert or update asset
        if(InsertRegister){
      		insert RelatedAsset;
        }
        else{
      		update RelatedAsset;
        }
        
        if(RelatedAsset != null && RelatedAsset.Id != null){
          
          	//reference quote item with created asset
          	QuoteLineItem qi1 = new QuoteLineItem();
            qi1.Activo_producido__c = RelatedAsset.id;
            qi1.Id = qi.Id;
            update qi1;
        
        	//create production mov
        	UpsertProductionMov(qi, RelatedAsset);
        }
        //TODO:create task to create asset
    }  
  
  	/*calculate new asset code*/
  	private static Integer CalcNewAssetCode(Asset AssetToEval, AggregateResult[] qrAux ){
		//get min asset code
        Integer NewAssetCode = CL000_Utils.C_MinAssetCode;
                
        if(AssetToEval != null && 
          AssetToEval.Codigo_activo__c != null){

          	//get existing asset code                    
        	NewAssetCode = Integer.valueof(AssetToEval.Codigo_activo__c);

      	}
      	else{
                  
      		
                  
          	if(qrAux.size() == 1 && 
            	qrAux[0].get('Max_Codigo_activo__c') != null){
                
            	NewAssetCode = Integer.valueOf(qrAux[0].get('Max_Codigo_activo__c')) + 1;
          	}                  
      	}
      	
      	return NewAssetCode;  
  	}
  	
  	private static void UpsertProductionMov(QuoteLineItem qli,Asset RelatedAsset){
  	
  		//validate production mov creation
      	if(qli.PricebookEntry.Product2.Genera_Produccion__c &&
    		!string.isblank(string.valueof(qli.PricebookEntry.Product2.Tipo_de_produccion__c))){
                
    		//get current production movement
            string[] strTM = new string[]{CL000_Utils.C_NewProductionMovStatus,CL000_Utils.C_RenewProductionMovStatus};
            Movimiento_produccion__c[] ProdMovementLst = 
		                  [select id,
			                      Name,
			                      RecordTypeId,
			                      Activo__c,
			                      Ano_Fiscal__c,
			                      Etapa__c,
			                      Token_publicidad__c,//JAAR 22-01-2014 modificacion para sincronizar el token de publicidad
			                      Localidad_venta__c,//JAAR 23-01-2014 Se agrega modificacion para sincronizar la cudad de venta
			                      Tipo_movimiento__c
		                  from   Movimiento_produccion__c
		                  where   Activo__c =: RelatedAsset.id
		                  			and Tipo_movimiento__c in: strTM];
                      
        	//create new production movement
         	 Movimiento_produccion__c RelatedProductionMovement = new Movimiento_produccion__c();
          
          	//validate if production movement exists
          	if(ProdMovementLst.size() > 0){
            	RelatedProductionMovement = ProdMovementLst[0];
          	}                      
              
            //set record type
          	RelatedProductionMovement.RecordTypeId = 
	              [select	id 
	               from   	RecordType 
	               where  	SobjectType = 'Movimiento_produccion__c' 
	               			and IsActive = true
	               			and name =: qli.PricebookEntry.Product2.Tipo_de_produccion__c
	               limit   1][0].id;
              
            string ProdMovName = RelatedAsset.Name + '_MP';
            if(ProdMovName.length() > 75){
            	ProdMovName = ProdMovName.substring(0, 75); 
            }
           
          	RelatedProductionMovement.Name = ProdMovName;
          	RelatedProductionMovement.Activo__c = RelatedAsset.Id;
          	RelatedProductionMovement.Ano_Fiscal__c = RelatedAsset.Ano_Fiscal__c;
          	RelatedProductionMovement.Etapa__c = CL000_Utils.C_NewProductionMovementStage;
          	RelatedProductionMovement.Localidad_venta__c = RelatedAsset.Localidad_venta__c;//JAAR 23-01-2014 Se agrega modificacion para sincronizar la cudad de venta
          	RelatedProductionMovement.Token_publicidad__c = qli.Token_publicidad__c;
          
          	if(qli.Activo_renovacion__c == null){
            	RelatedProductionMovement.Tipo_movimiento__c = CL000_Utils.C_NewProductionMovStatus;
          	}
          	else{
            	RelatedProductionMovement.Tipo_movimiento__c = CL000_Utils.C_RenewProductionMovStatus;
          	}

			//insert update production movement	
          	if(ProdMovementLst.size() > 0){
            	update RelatedProductionMovement;
          	}
          	else{
            	insert RelatedProductionMovement;  
          	}
		}
	}
  	
	/*cancel assets*/
    private static void CancelAssets(Opportunity op, QuoteLineItem qi, Movimiento_produccion__c RelProdMov){
      
      	//cancel asset
      	if(qi.Activo_producido__r != null){
      		qi.Activo_producido__r.Status = CL000_Utils.C_DeleteAssetStatus;

      		update qi.Activo_producido__r;
      		
	      	/*Movimiento_produccion__c[] RelProdMov =
	      		[select	id
	                 	,Name
	                 	,Etapa__c
	             from 	Movimiento_produccion__c
	             where 	Activo__c =: qi.Activo_producido__r.id];*/
      	
      
	      	//cancel production mov
	      	if(RelProdMov != null){
	      		
	      		//for(Movimiento_produccion__c pm: RelProdMov){
	      			RelProdMov.Etapa__c = CL000_Utils.C_DeleteProductionMovementStage;
	      			update RelProdMov;
	      		//}
	    	}      	
      	}
	}
  	                 
  	/***************ASSET LIFE TIME ************************************/
    
    public static void AssetsLifeTime(Asset[] oAssets) {
      
    for (Asset CurrentAsset :oAssets){
    
      //validate production movement stage
      if(CurrentAsset.Status == CL000_Utils.C_FinalizedAssetStatus &&
        CurrentAsset.UsageEndDate == null){
        
         //get product info
            Product2[] RelatedProduct = 
                [select Id,
                     ProductCode,
                     Meses_Vigencia__c
                 from   Product2
                 where   IsActive = true
                     and id =: CurrentAsset.Product2Id]; 

        if(RelatedProduct.size() == 1){
          
          Asset AssetToUpdate = 
            [select  id,
                InstallDate,
                UsageEndDate,
                Activo_relacionado__c,
                Fecha_primera_activacion__c,
                Fecha_vencimiento_anterior__c
            from   asset
            where   id =: CurrentAsset.Id];

          //get related asset
          Asset[] RelatedAsset = null;
          if(AssetToUpdate.Activo_relacionado__c != null){
            RelatedAsset =
              [select id,
                  name,
                  UsageEndDate,
                  Fecha_primera_activacion__c
              from   asset
              where   id =: AssetToUpdate.Activo_relacionado__c];
          }

          if(RelatedAsset == null){
            //new sale
            AssetToUpdate.Fecha_primera_activacion__c = system.today(); 
            AssetToUpdate.InstallDate = system.today();
            AssetToUpdate.UsageEndDate = system.today().addMonths(integer.valueof(RelatedProduct[0].Meses_Vigencia__c));
          }
          else{
            //renew sale
            AssetToUpdate.Fecha_primera_activacion__c = RelatedAsset[0].Fecha_primera_activacion__c; 
            AssetToUpdate.Fecha_vencimiento_anterior__c = RelatedAsset[0].UsageEndDate;
            AssetToUpdate.InstallDate = system.today();
            
            if(RelatedAsset[0].UsageEndDate > system.today()){
              AssetToUpdate.UsageEndDate = RelatedAsset[0].UsageEndDate.addMonths(integer.valueof(RelatedProduct[0].Meses_Vigencia__c));
            }
            else{
              AssetToUpdate.UsageEndDate = system.today().addMonths(integer.valueof(RelatedProduct[0].Meses_Vigencia__c));
            }
          }
          
          //close end usage day to 1 or 15 day in month
          if(AssetToUpdate.UsageEndDate.day() > 1 || AssetToUpdate.UsageEndDate.day() <= 15){
            AssetToUpdate.UsageEndDate.addDays(15 - AssetToUpdate.UsageEndDate.day()); 
          }
          else{
            AssetToUpdate.UsageEndDate.addMonths(1);
            AssetToUpdate.UsageEndDate = Date.newInstance
              (AssetToUpdate.UsageEndDate.year(),
              AssetToUpdate.UsageEndDate.Month(),
              1);
          }
          
          update AssetToUpdate;
        }  
      }
    }
    }
    

   
  //JAAR 20-01-2014 metodo que actualiza el estado del activo en la medida en que se cambie el estado del movimiento de produccion 
   //update assets
   public static void UpsertStatus(List<Movimiento_produccion__c> lstNewDat)
   {
   	system.debug('JDDEBUG2: lstNewDat: '+lstNewDat);
   	 if(lstNewDat!=null)        
         { 
         	try{
             	if(lstNewDat.size() == 1 )            
                   {
                    	Movimiento_produccion__c mvmprd = lstNewDat[0];
                    	
                    	list <Asset> Assetactual = [ select Status,
					                                 Activo_relacionado__c,Codigo_activo__c, Codigo_internet__c
					                                 from asset
			                      					 where id =: mvmprd.Activo__c];
			                      					 
			           
                        system.debug('JDDEBUG2: lstNewDat: '+lstNewDat);
                        
                        if(mvmprd.Etapa__c == '01. Por Producir'){
                        	Assetactual[0].Status = '01. Creado';
                        }
                        else if(mvmprd.Etapa__c == '99. Entregado')
                        {
                        	Assetactual[0].Status = '03. Activo';
                        }else if(mvmprd.Etapa__c =='95. Anulado')
                        {
                        	Assetactual[0].Status = '06. Anulado';
                        }else if(mvmprd.Etapa__c =='94. Suspendido')
                        {
                        	Assetactual[0].Status = '07. Suspendido';
                        }else if(mvmprd.Etapa__c =='04. Pausado')
                        {
                        	Assetactual[0].Status = '05. Pausado';
                        }else
                        {
                        	Assetactual[0].Status = '02. En Producción';
                        }
                        update Assetactual;
                   }
                   
         	 }catch(system.exception e)
			{
   				system.debug('MENSAEJEOP=='+e.getMessage());	
         	}
         }
   }
   
	/*Exception class*/	
	public class CL002_AssetsProcessing_Exception extends Exception{}   
   
}