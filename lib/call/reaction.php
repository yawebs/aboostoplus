<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error='';


 
    $propertyId =$_POST['propertyId'];
    $userId = $_POST['userId'];
    $userName = $_POST['userName'];
    $reactionType= $_POST['reactionType'];



   

 $exec=  $helper->reactOnProperty($propertyId,$userId,$userName,$reactionType);
if($exec==true){
    $response->status=true;
    $response->message='Successful';
}else{
    $response->status=false;

    $response->message='Unable to add items to database';
}
  
header('Content-type: application/json');
echo json_encode($response);
 

