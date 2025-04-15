public class LRAMSPEligibilityWrapper {
    public String resourceType;
    public String id;
    public String type;
    public Integer total;
    public List<Link> link;
    public List<Entry> entry;
    
    public class Link {
        public String relation;
        public String url;
    }
    
    public class Entry {
        public String fullUrl;
        public Resource resource;
    }
    
    public class Resource {
        public String resourceType;
        public String id;
        public Meta meta;
        public List<Extension> extension;
        public String status;
        public List<String> purpose;
        public Patient patient;
        public String servicedDate;
        public String created;
        public Request request;
        public String outcome;
        public String disposition;
        public Insurer insurer;
        public List<Insurance> insurance;
    }
    
    public class Meta {
        public List<String> profile;
    }
    
    public class Extension {
        public String url;
        public String valueString;
    }
    
    public class Patient {
        public Identifier identifier;
    }
    
    public class Identifier {
        @jsonProperty('system')
        public String systemUrl;
        public String value;
    }
    
    public class Request {
        public String reference;
    }
    
    public class Insurer {
        public String display;
    }
    
    public class Insurance {
        public Coverage coverage;
        public Boolean inforce;
    }
    
    public class Coverage {
        public String reference;
    }
    
    public static LRAMSPEligibilityWrapper parse(String jsonString) {
        return (LRAMSPEligibilityWrapper) JSON.deserialize(jsonString, LRAMSPEligibilityWrapper.class);
        
    }
}