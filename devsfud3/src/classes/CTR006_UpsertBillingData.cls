/*
*   Controller for opportunity s3 file 
*   Version 1.0		15-01-2013 - Jairo Guzman - control new file creation into amazon S3 from opportunity 
    Version 1.1 	17-02-2015 - JAAR           Se modificacion en el dato de facturación para que soporte diferentes tipos de facturación 
    											por vigencias, por cuotas iguales y por cuotas especiales
*/

public class CTR006_UpsertBillingData {
    
    /*Context properties*/
    private Dato_facturacion__c oCurrentBillingInfo;
    public List<QuoteLineItem> loadnumcuotas;
    public boolean rendervigencias{get;set;}
        public boolean rendercuotas{get;set;}
        public boolean rendercespeciales{get;set;}
        public boolean rendervalores{get;set;}
        public boolean renderNie{get;set;}
        public boolean requiredNie{get;set;}
        public boolean requiredvigencias{get;set;}
        public boolean requiredcuotas{get;set;} 
        public Decimal numcuotprod{get;set;} 
    public Dato_facturacion__c CurrentBillingInfo{ 
        get {
            if(oCurrentBillingInfo == null){
                oCurrentBillingInfo = (Dato_facturacion__c)CtxController.getRecord();
            }
            return oCurrentBillingInfo;
        }
        set{
            oCurrentBillingInfo = value;
        }
    }

    private Quote oRelatedQuoteInfo;
    public Quote RelatedQuoteInfo{
        get{
            if(oRelatedQuoteInfo == null){
                //get related account info
                oRelatedQuoteInfo =
                    [select TotalPrice
                            ,Name
                            ,Opportunity.Account.Name
                            ,Opportunity.Account.Tipo_identificacion__c
                            ,Opportunity.Account.Numero_identificacion__c
                            ,Opportunity.Account.Ciudad_facturacion__c
                            ,Opportunity.Account.Direccion_facturacion__c
                            ,Opportunity.Account.Telefono_facturacion__c
                            ,Opportunity.Account.Email_corporativo__c
                    from    Quote
                    where   id =: CurrentBillingInfo.Presupuesto__c][0];
            }
            return oRelatedQuoteInfo; 
        }
        set{oRelatedQuoteInfo = value;}
    }
     
    private decimal oMaxBillingValue;
    public decimal MaxBillingValue{
        get{
            if(oMaxBillingValue == null){
            
                AggregateResult TotalBilling = null;
                
                if(CurrentBillingInfo.Id != null){
                    TotalBilling = 
                        [select sum(Valor_facturacion__c)Valor_facturacion__c
                        from    Dato_facturacion__c
                        where   Presupuesto__c =: CurrentBillingInfo.Presupuesto__c
                                and id !=: CurrentBillingInfo.id][0];
                }
                else{
                    TotalBilling = 
                        [select sum(Valor_facturacion__c)Valor_facturacion__c
                        from    Dato_facturacion__c
                        where   Presupuesto__c =: CurrentBillingInfo.Presupuesto__c][0];
                }
                
                
                if(TotalBilling != null && TotalBilling.get('Valor_facturacion__c') == null){
                    oMaxBillingValue = RelatedQuoteInfo.TotalPrice;
                }
                else if(TotalBilling != null && RelatedQuoteInfo.TotalPrice > (decimal)TotalBilling.get('Valor_facturacion__c')){
                    oMaxBillingValue = RelatedQuoteInfo.TotalPrice - (decimal)TotalBilling.get('Valor_facturacion__c');
                }           
            }
            return oMaxBillingValue;
        }
        set{oMaxBillingValue = value;}
    }   
    
    
    public string DisplayQuote{
        get{
            if(CurrentBillingInfo.Id != null){
                return '';
            }
            else{
                return 'none';
            }
        }
    }
    
    ApexPages.StandardController CtxController;
    public CTR006_UpsertBillingData(ApexPages.StandardController stdController) {
        CtxController = stdController;
        
        oCurrentBillingInfo = (Dato_facturacion__c)CtxController.getRecord();
        if(oCurrentBillingInfo.id == null)
        {
            rendervalores = true;
	        requiredcuotas = true;
	        rendercuotas = true;
	        oCurrentBillingInfo.billing_type__c = 'Facturación por cuotas iguales';
	        oCurrentBillingInfo.Numero_cuotas__c = 1;
	        oCurrentBillingInfo.Cuota_normalizada__c = true;
	        requiredNie = false; 
        }else
        {
	        if(oCurrentBillingInfo.billing_type__c == 'Facturación por cuotas iguales')
	        {
	        	rendervalores = true;
	        	requiredcuotas = true;
	        	rendercuotas = true;
	        }else if(oCurrentBillingInfo.billing_type__c == 'Facturación Especial')
	        {
	        	requiredcuotas = true;
	        	rendercuotas = true;
	        	rendercespeciales = true;
	        	oCurrentBillingInfo.Cuota_normalizada__c = false;
	        }else
	        {
	        	requiredvigencias = true;
	        	rendervigencias = true;
	        	
	        }
	        if(oCurrentBillingInfo.Agente_recaudo__c == 'CODENSA')
	        {
	        	requiredNie = true; 
	        	renderNie = true;
	        	
	        }else
	        {
	        	requiredNie = false; 
	        	renderNie = false;
	        }
        }    
    }
    
    /*load page*/
    public pageReference LoadPage() {
        
        try{
            if(CurrentBillingInfo.Id == null){
               
                CurrentBillingInfo.Razon_social__c = RelatedQuoteInfo.Opportunity.Account.Name;
                CurrentBillingInfo.Tipo_identificacion__c = RelatedQuoteInfo.Opportunity.Account.Tipo_identificacion__c;
                CurrentBillingInfo.Numero_identificacion__c = RelatedQuoteInfo.Opportunity.Account.Numero_identificacion__c;
                CurrentBillingInfo.Ciudad_facturacion__c = RelatedQuoteInfo.Opportunity.Account.Ciudad_facturacion__c;
                CurrentBillingInfo.Ciudad_telefono_facturacion__c = RelatedQuoteInfo.Opportunity.Account.Ciudad_facturacion__c;
                CurrentBillingInfo.Direccion_facturacion__c = RelatedQuoteInfo.Opportunity.Account.Direccion_facturacion__c;
                CurrentBillingInfo.Telefono_contacto_financiero__c = RelatedQuoteInfo.Opportunity.Account.Telefono_facturacion__c;
                CurrentBillingInfo.Correo_facturacion__c = RelatedQuoteInfo.Opportunity.Account.Email_corporativo__c;
                CurrentBillingInfo.Valor_facturacion__c = MaxBillingValue;
                CurrentBillingInfo.Name = RelatedQuoteInfo.Name + ' ' + String.valueOf(system.today());
            }
        }catch(Exception er){
             
             ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, er.getMessage());
             ApexPages.addMessage(errorMsg);
        }
        return null;
    }   
    
    /*modify billing info*/
    public pageReference UpsertBillingInfo() {

        try{
        	
        	//JAAR - 17-02-2015 -------------FACTURACION POR CUOTAS IGUALES O ESPECIAL --------------------------------------------------------
         if(CurrentBillingInfo.billing_type__c == 'Facturación por cuotas iguales'||CurrentBillingInfo.billing_type__c =='Facturación Especial')
         {
            if(CurrentBillingInfo.Numero_cuotas__c > 0){

                //JAAR 17-02-2015 Verificar que ninguno de los productos de la cotización tengan el campo Numero_cuotas_maximo__c null o en cero antes de iniciar el proceso.
                   loadnumcuotas = [SELECT Id,QuoteId,PricebookEntry.Product2.Numero_cuotas_maximo__c ,PricebookEntry.Product2.Name FROM QuoteLineItem WHERE QuoteId =: CurrentBillingInfo.Presupuesto__c];
                   if(loadnumcuotas.size()<1)
                   {
                   	  ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'Antes de crear el dato de facturación verifique que su cotización tenga al menos un producto: ');
                                            ApexPages.addMessage(errorMsg);
                                            return null;
                   }
                   for(QuoteLineItem qli: loadnumcuotas)
                   {
                        if(qli.PricebookEntry.Product2.Numero_cuotas_maximo__c <> null)
                        {
                                if(qli.PricebookEntry.Product2.Numero_cuotas_maximo__c < 1)
                                {
                                        ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'El número de cuotas maximo configurado en el producto: ' + qli.PricebookEntry.Product2.Name + ' debe ser mayor a cero (0).');
                                            ApexPages.addMessage(errorMsg);
                                            return null;
                                }
                        }else
                        {
                                ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'El número de cuotas maximo configurado en el producto: ' + qli.PricebookEntry.Product2.Name + ' debe tener valor numerico');
                                        ApexPages.addMessage(errorMsg);
                                        return null;
                        }
                   }
                
                
                
                if(CurrentBillingInfo.Id == null){
                    
                    CL006_BillingRules CurrentBillingRules = new CL006_BillingRules(CurrentBillingInfo);
                                
                    //create billing
                    CurrentBillingRules.CreateBillingRecord();
                }
                else{
                    //update billing
                    system.debug('\n\n Es_una_modificacion_del_dato' + Apexpages.currentPage().getParameters().keySet() );
                    //create an object with request params
                    List<Cuota_facturacion__c> lstQuoteToUpdate = new List<Cuota_facturacion__c>();
                    map<Decimal,Date> lstQuoteDate = new map<Decimal,Date>();
                    
                    
                    //verificar si ademas se necesita una condicion adicional para fact por vigencias
                    if(CurrentBillingInfo.billing_type__c =='Facturación Especial')
                    {
	                    for(string strQuoteId:Apexpages.currentPage().getParameters().keySet())
	                    {
	                        system.debug('strQuoteId===>>> '+strQuoteId);
	                        if(strQuoteId.contains('QuoteObjectId')){
	                            
	                            Cuota_facturacion__c upq = new Cuota_facturacion__c(Dato_facturacion__c = CurrentBillingInfo.id);
	                            
	                            upq.Id = Apexpages.currentPage().getParameters().get(strQuoteId);
	                            upq.Valor_cuota__c = decimal.valueOf(Apexpages.currentPage().getParameters().get(strQuoteId.replace('QuoteObjectId','Field_QuoteValue')).replace('.','').replace(',','.'));
	                            upq.Partida_de_presupuesto__c = Apexpages.currentPage().getParameters().get(strQuoteId.replace('QuoteObjectId','QuoteLineItemId'));
	                            upq.No_Cuota__c = Integer.valueof(Apexpages.currentPage().getParameters().get(strQuoteId.replace('QuoteObjectId','QuoteNumber')));
	                            system.debug('upq_Valor_cuota__c_new'+upq.Valor_cuota__c);
	                            if(!lstQuoteDate.containsKey(upq.No_Cuota__c)){
	                                lstQuoteDate.put(upq.No_Cuota__c,
	                                    getTimeInFormat(Apexpages.currentPage().getParameters().get(strQuoteId.replace('QuoteObjectId','Field_QuoteDate'))));
	                            }
	                            upq.Fecha_cuota__c = lstQuoteDate.get(upq.No_Cuota__c);
	                                                                                    
	                            lstQuoteToUpdate.add(upq);
	                        }           
	                    }
                    }else
                    {
                    	lstQuoteToUpdate = getQuoteInfo();
                        system.debug('lstQuoteToUpdate============>>>  '+lstQuoteToUpdate);
                    }
                    
                    //update billing information
                    CL006_BillingRules CurrentBillingRules = new CL006_BillingRules(CurrentBillingInfo.Id);
                    CurrentBillingRules.UpdateBillingRecord(CurrentBillingInfo,lstQuoteToUpdate);
                }
            }
            else{
                ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'El número de cuotas debe ser mayor a cero (0).');
                ApexPages.addMessage(errorMsg);
            }
         } 
         
       //fact vigencia
         
              
      }catch(Exception er){
      	    system.debug('\n\n ERROR_PRESENTADO == \n' +'Linea:: ' + string.valueof(er.getLineNumber()) + '::' +  
                'Linea:: ' +  string.valueof(er.getStackTraceString()) + '::' +
                er.getMessage()+'\n');
                
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.INFO,  + 'No fue posible guardar el dato de facturación ' + er.getMessage());
            ApexPages.addMessage(errorMsg);
        }
        return null;    
    }
    /*
    **** JAAR 17-02-2015 Metodo que muestra u oculta los campos necesarios para el agente de recaudo codensa
    */
     public Pagereference renderagrecaudo(){
     	system.debug('entro_a_renderagrecaudo');
     	if(CurrentBillingInfo.Agente_recaudo__c == 'CODENSA') 
     	{
     		renderNie = true;
     		requiredNie = true;
     	}
     	if(CurrentBillingInfo.Agente_recaudo__c == 'FACTURA DIRECTA')
     	{
     		renderNie = false;
     		requiredNie = false;
     		CurrentBillingInfo.NIE__c = null; //si se selecciona esta opcion se borra el nie ya que no es requerido ni aplica
     	}
     	
     	return null;
     }
     
     public pageReference renderpage() {
                    //JAAR 17-02-2015 mostrar o ocultar la seccion de vigencias -----------------------------------------------
                system.debug('entro_a_renderpage');
                //1 - visualizacion de facturacion por vigencias
                if(CurrentBillingInfo.billing_type__c == 'Facturación por vigencia')
                 {
                        rendervigencias = true;
                        CurrentBillingInfo.Cuota_normalizada__c = true;
                        system.debug('dato_por__vigencias  ' + CurrentBillingInfo.billing_type__c + ' ' + rendervigencias);
                        
                        //CurrentBillingInfo.Numero_cuotas__c = 1; //pend ***********************************************
                        requiredcuotas = false;
                        requiredvigencias = true;
                 }else
                 {
                        rendervigencias = false;
                        requiredcuotas = true; 
                        requiredvigencias = false;
                        system.debug('dato_por_de_vigencias' + CurrentBillingInfo.billing_type__c + rendervigencias);
                 }
                 //2- visualizacion de facturacion por cuotas
                 if(CurrentBillingInfo.billing_type__c == 'Facturación por cuotas iguales')
                 {
                        rendercuotas = true;
                        CurrentBillingInfo.Cuota_normalizada__c = true;
                        requiredvigencias = false;
                 }else
                 {
                        rendercuotas = false;
                 }
                    //2- visualizacion de facturacion por cuotas especiales
                 if(CurrentBillingInfo.billing_type__c == 'Facturación Especial')
                 {
                        rendercespeciales = true;
                        rendervalores = false;
                        rendercuotas = true;
                        requiredvigencias = false;
                        CurrentBillingInfo.Cuota_normalizada__c = false; // JAAR - se deja editable para que el asesor pueda acomodar los valores a su parecer
                 }else
                 {
                        rendercespeciales = false;
                        rendervalores = true;
                 }
                     
                
                 return null;
         }
        
    
    
    
    private Date getTimeInFormat(string strToParse){

        Date oRetorno = date.newinstance
            (Integer.valueOf(strToParse.split('/')[2]),
            Integer.valueOf(strToParse.split('/')[1]),
            Integer.valueOf(strToParse.split('/')[0])); 
    
        return oRetorno;
    }

    
      //JAAR 17-02-2015 Se realiza modificacion para qwue el darto de facturación soporte varios tipos de facturación
  //devuelbe lista de productos por cotización
  public List<QuoteLineItem> getQuoteLineIteminf() {
          List<QuoteLineItem> qlitem = [SELECT Id,QuoteId,Numberquota__c,PricebookEntry.Product2.ProductCode,PricebookEntry.Product2.Name,Quantity,TotalPrice FROM QuoteLineItem
                                        WHERE  QuoteId =:CurrentBillingInfo.Presupuesto__c ];  
         
           if(qlitem.size()>0){
                system.debug('getQuoteLineIteminf_Retorno_LOS_PRODUCTOS--> '+qlitem);
            return qlitem;
        }else{
                system.debug('getQuoteLineIteminf_Retorno null--> ');
            return null;
        }
        
        
  } 
    
    
    /*get related quote info*/
    public List<Cuota_facturacion__c> getQuoteInfo(){
        
        List<Cuota_facturacion__c> oRetorno = new List<Cuota_facturacion__c>();
        
        if(CurrentBillingInfo.Id != null){
            
            oRetorno = 
                [select id
                        ,No_Cuota__c
                        ,Partida_de_presupuesto__c
                        ,Valor_cuota__c
                        ,Fecha_cuota__c
                        
                        ,Dato_facturacion__c
                        
                        ,Partida_de_presupuesto__r.LineNumber
                        ,Partida_de_presupuesto__r.PricebookEntry.Product2.Name
                        ,Partida_de_presupuesto__r.PricebookEntry.Product2.ProductCode
                         ,Partida_de_presupuesto__r.PricebookEntry.Product2.Numero_cuotas_maximo__c
                from    Cuota_facturacion__c
                where   Dato_facturacion__c =: CurrentBillingInfo.Id
                order by No_Cuota__c,Partida_de_presupuesto__r.LineNumber];

        }
        
        return oRetorno; 
    }
}