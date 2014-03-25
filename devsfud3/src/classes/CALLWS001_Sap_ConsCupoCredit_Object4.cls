//Generated by wsdl2apex

public class CALLWS001_Sap_ConsCupoCredit_Object4 {
    public class ProductCategoryInternalID {
        public String schemeID;
        public String schemeAgencyID;
        private String[] schemeID_att_info = new String[]{'schemeID'};
        private String[] schemeAgencyID_att_info = new String[]{'schemeAgencyID'};
        private String[] apex_schema_type_info = new String[]{'http://sap.com/xi/FSCM/Global','false','false'};
        private String[] field_order_type_info = new String[]{};
    }
    public class PartyInternalID {
        public String schemeID;
        public String schemeAgencyID;
        private String[] schemeID_att_info = new String[]{'schemeID'};
        private String[] schemeAgencyID_att_info = new String[]{'schemeAgencyID'};
        private String[] apex_schema_type_info = new String[]{'http://sap.com/xi/FSCM/Global','false','false'};
        private String[] field_order_type_info = new String[]{};
    }
    public class ExchangeLogData {
        public String severity;
        public String text;
        public String url;
        public String id;
        private String[] severity_type_info = new String[]{'severity','http://sap.com/xi/FSCM/Global',null,'0','1','false'};
        private String[] text_type_info = new String[]{'text','http://sap.com/xi/FSCM/Global',null,'1','1','false'};
        private String[] url_type_info = new String[]{'url','http://sap.com/xi/FSCM/Global',null,'0','1','false'};
        private String[] id_type_info = new String[]{'id','http://sap.com/xi/FSCM/Global',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://sap.com/xi/FSCM/Global','false','false'};
        private String[] field_order_type_info = new String[]{'severity','text','url','id'};
    }
    public class CrdtWrthnsRspCrdtrPty {
        public CALLWS001_Sap_ConsCupoCredit_Object4.PartyInternalID InternalID;
        private String[] InternalID_type_info = new String[]{'InternalID','http://sap.com/xi/FSCM/Global',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://sap.com/xi/FSCM/Global','false','false'};
        private String[] field_order_type_info = new String[]{'InternalID'};
    }
    public class DateTimePeriod {
        public String StartDateTime;
        public String EndDateTime;
        private String[] StartDateTime_type_info = new String[]{'StartDateTime','http://sap.com/xi/FSCM/Global',null,'0','1','false'};
        private String[] EndDateTime_type_info = new String[]{'EndDateTime','http://sap.com/xi/FSCM/Global',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://sap.com/xi/FSCM/Global','false','false'};
        private String[] field_order_type_info = new String[]{'StartDateTime','EndDateTime'};
    }
    public class CrdtWrthnsRspSlrPty {
        public CALLWS001_Sap_ConsCupoCredit_Object4.PartyInternalID InternalID;
        private String[] InternalID_type_info = new String[]{'InternalID','http://sap.com/xi/FSCM/Global',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://sap.com/xi/FSCM/Global','false','false'};
        private String[] field_order_type_info = new String[]{'InternalID'};
    }
    public class CrdtWrthnsRspProdCat {
        public CALLWS001_Sap_ConsCupoCredit_Object4.ProductCategoryInternalID InternalID;
        private String[] InternalID_type_info = new String[]{'InternalID','http://sap.com/xi/FSCM/Global',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://sap.com/xi/FSCM/Global','false','false'};
        private String[] field_order_type_info = new String[]{'InternalID'};
    }
    public class ExchangeFaultData {
        public String faultText;
        public String faultUrl;
        public CALLWS001_Sap_ConsCupoCredit_Object4.ExchangeLogData[] faultDetail;
        private String[] faultText_type_info = new String[]{'faultText','http://sap.com/xi/FSCM/Global',null,'1','1','false'};
        private String[] faultUrl_type_info = new String[]{'faultUrl','http://sap.com/xi/FSCM/Global',null,'0','1','false'};
        private String[] faultDetail_type_info = new String[]{'faultDetail','http://sap.com/xi/FSCM/Global',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'http://sap.com/xi/FSCM/Global','false','false'};
        private String[] field_order_type_info = new String[]{'faultText','faultUrl','faultDetail'};
    }
}