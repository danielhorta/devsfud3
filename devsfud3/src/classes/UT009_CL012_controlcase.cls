/**                                                     
* ===================================================================================================================================
*  Desarrollado por:    Joe Alexander Ayala
*  Fecha:               Febrero 03 de 2014
*  Decripción:          Clase de prueba del proceso de chequeo de crédito con SAP
*  @version:            1.0
* ===================================================================================================================================
**/

@isTest (SeeAllData=true)
public with sharing class UT009_CL012_controlcase {

static testMethod void fnTest1() 
    {
    	fnCrearData();
        Test.startTest();
        system.debug('prueba cerrar caso'  );
        Test.stopTest();
    }
    
 static void fnCrearData()
    {
        try{
	           system.debug('Entro_a_fnCrearData');	 
	  			//----
		       Date DateOpp = date.newinstance(2136, 12, 31);	
		       Date Datemen = date.newinstance(2012, 12, 31);	
		       Profile prof=[Select Id from Profile limit 1];
		  
		       User usrgestor=new User();
		            usrgestor.FirstName='Prueba';
		            usrgestor.LastName='Manager';
		            usrgestor.Username='GESTORwdsads@publicar.com';
		            usrgestor.Email='GESTOR@publicar.com';
		            usrgestor.Alias='rsdsd';
		            usrgestor.Country= 'Colombia';
		            usrgestor.City = 'Bogotá D.C.';
		            usrgestor.CommunityNickname='p-asesor1sdd';
		            usrgestor.TimeZoneSidKey='GMT';
		            usrgestor.LocaleSidKey='es_CO';
		            usrgestor.EmailEncodingKey='ISO-8859-1';
		            usrgestor.ProfileId=prof.Id;
		            usrgestor.LanguageLocaleKey='es';
		            insert usrgestor;
		         
		        User usr=new User();
		            usr.FirstName='Prueba';
		            usr.LastName='Asesor';
		            usr.Username='asesorsddad@publicar.com';
		            usr.Email='asesor@publicar.com';
		            usr.Alias='orcvcv';
		            usr.Country= 'Colombia';
		            usr.City = 'Bogotá D.C.';
		            usr.CommunityNickname='p-asesorvcx';
		            usr.TimeZoneSidKey='GMT';
		            usr.LocaleSidKey='es_CO';
		            usr.EmailEncodingKey='ISO-8859-1';
		            usr.ProfileId=prof.Id;
		            usr.LanguageLocaleKey='es';
		            usr.ManagerId = usrgestor.Id;
		            insert usr;
		            system.debug('creamos_el_User' + usr);	
		            
		            Ciudad__c city = new Ciudad__c();
		           city.Capital__c = 'Es capital de pais';
		           city.Codigo_capital__c = '203';
		           city.Codigo_ciudad__c = '11001';
		           city.Codigo_estado__c = '11';
		           city.Codigo_pais__c = '1';
		           city.Codigo_region__c = '11001';
		           city.Estado__c = 'Distrito Capital';
		           city.Name = 'BOGOTA';
		           city.Pais__c = 'Colombia';
		           city.Region__c = 'Centro';
		           insert city;
		           system.debug('creamos_la_Ciudad__c' + city);	
		            
		        Account acc1 = new Account();
		            acc1.Activo__c = true;
		            acc1.Codigo_cliente_unico__c = 123;
		            acc1.Name = 'cuenta1';
		            acc1.OwnerId= usr.Id;
		            insert acc1;
		             system.debug('creamos_Account' + acc1);	
		             
		        Account acc2 = new Account();
		            acc2.Activo__c = true;
		           
		            acc2.Name = 'cuenta2';
		            acc2.OwnerId= usr.Id;
		            insert acc2;        
		            
       
                case caso1 = new case();
                caso1.AccountId = acc1.id;
                caso1.Description = 'mi caso prueba';
                caso1.Status = 'Nuevo';
                caso1.Origin = 'Telefónico';
                caso1.Priority = 'Media';
                caso1.Ciudad_de_reclamacion__c= city.id;
                caso1.Nombres_contacto__c = 'Usuario 1';
                caso1.Apellidos_contacto__c= 'apellidos';
                caso1.Telefono_contacto__c = '123456';
                caso1.Correo_electronico_del_contacto__c = 'mimail@yahoo.es';
                insert caso1;
                
                
                 case subcaso1 = new case();
                subcaso1.AccountId = acc1.id;
                subcaso1.Description = 'mi subcaso prueba';
                subcaso1.Status = 'Nuevo';
                subcaso1.Origin = 'Telefónico';
                subcaso1.Priority = 'Media';
                subcaso1.Ciudad_de_reclamacion__c= city.id;
                subcaso1.ParentId = caso1.id;
                insert subcaso1;
        
                caso1.Status = 'Cerrado';
                update caso1;
            
          
        
           
		}catch(System.exception ex)
	        {
	            System.debug('\n\n ##Error##' + ex + '\n\n');
	        }
   
    }
}