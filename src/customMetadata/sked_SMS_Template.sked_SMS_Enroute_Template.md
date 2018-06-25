<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>SMS Enroute Template</label>
    <protected>false</protected>
    <values>
        <field>sked_Phone_Field_API_Name__c</field>
        <value xsi:type="xsd:string">sked__job__r.sked__contact__r.mobilephone</value>
    </values>
    <values>
        <field>sked_Template__c</field>
        <value xsi:type="xsd:string">Hi {{sked__job__r.sked__account__r.name}}, 
{{sked__resource__r.name}} is on the way to your place.</value>
    </values>
</CustomMetadata>
