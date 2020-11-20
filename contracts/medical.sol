pragma solidity 0.5.0;
pragma experimental ABIEncoderV2;

contract  medical{
    

    address  hospital ; // 醫院EOA

    //病歷資料
    struct MedicalRecord{
        string symptom ; //症狀
        string cause ; //病因
        uint time ; //住院日期
        uint day;  // 住院天數
        uint cost; //住院花費
        bool exist; // 是否有紀錄
        bool pay ; //是否繳費
    }
    
    //病人資料
    struct patient{
        string name ; //姓名
        string addr ; //地址
        uint recordCount; //病歷總量
        mapping(uint => MedicalRecord) records; //病例
        address insuranceCorp ; // 保險公司
        bool exist; // 是否有紀錄
    }
    
 
    
    mapping(address => patient) private patientData;  //儲存病患所有資料
    mapping(address => mapping(address => bool)) authorization ; //授權狀態

    constructor()  public {
        hospital = msg.sender;    //醫院為合約擁有者 
    }
    
    modifier onlyHospital{
        require(hospital == msg.sender , "Only Hospital can use ");
        _;
    }
    

    
    //病患授權保險公司
    function setInsuranceCorp(address _insuranceCorp) public  {
        patientData[msg.sender].insuranceCorp = _insuranceCorp ;
        authorization[msg.sender][_insuranceCorp] = true ;
    } 
    
    //查詢保險EOA
    function getInsuranceCorp() public view returns(address){
        
        return patientData[msg.sender].insuranceCorp ;
        
    } 
    
    //新增病患基本資料
    function insert_patient(address _patient ,string memory _name , string memory _addr) public onlyHospital{
        
        require(!patientData[_patient].exist , "patient  exist");
        patientData[_patient].name = _name;
        patientData[_patient].addr = _addr ;
        patientData[_patient].recordCount = 0;
        patientData[_patient].exist = true ; 
    }
    
    
    //新增病患住院資料
    function insert_record(address  _patient,string memory _symptom , string memory _cause , uint _day , uint _cost) public onlyHospital returns(uint){
         require(patientData[_patient].exist == true , "patient  not  exist");
         
        uint index = patientData[_patient].recordCount +=1 ;
        
        MedicalRecord  memory record = MedicalRecord({
           symptom : _symptom ,
           cause : _cause ,
           time : now ,
           day : _day ,
           cost : _cost * 1 ether ,
           exist : true,
           pay : false
        });
        
        patientData[_patient].records[index] = record; //將病例儲存進病患資料中
        
        return index ; 
    }
    
    
    //病患繳清帳單
    function pay_to_hospital(uint _index ) public payable {
        require(patientData[msg.sender].exist == true , "patient  not  exist");
        require(patientData[msg.sender].records[_index].exist == true , "record  not  exist");
        require(patientData[msg.sender].records[_index].pay == false , "already pay money");
        require(patientData[msg.sender].records[_index].cost == msg.value , "pay error");
        
        patientData[msg.sender].records[_index].pay =true ;

        //轉帳到合約
        address(this).transfer(msg.value) ;

    }
    
    //保險公司申請病患資料
    function query_record(address _patient , uint _index) public view returns(MedicalRecord memory){
        
        require(authorization[_patient][msg.sender] == true, " insuranceCorp didnt authorization");
        require(patientData[_patient].exist == true , "patient  not  exist");
        require(patientData[_patient].records[_index].exist == true , "record  not  exist");
        
        return patientData[_patient].records[_index];
    } 
    
    
    //保險公司理賠給病患
    
    function pay_to_patient(address payable _patient , uint _index) public payable{
        require(authorization[_patient][msg.sender] == true, " insuranceCorp can not authorization");
        require(patientData[_patient].records[_index].pay == true , " you didnt pay to hospital");
        uint money =  patientData[_patient].records[_index].cost;
        require( money == msg.value , " value error ");
        _patient.transfer(msg.value);

    } 
    
    function contract_balance() public view returns(uint){
        
        return address(this).balance ;
    }
    
    
    function () external payable{}
    
}
