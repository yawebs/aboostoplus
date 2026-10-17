<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error='';


if(isset($_POST['userId']) && isset($_POST['currentUserId'])){
     
    $userId =$_POST['userId'];
    $currentUserId =$_POST['currentUserId'];
    $isUnfollowing= $_POST['isUnfollowing'];
   

 $exec=  $helper->addFollower($currentUserId,$userId,$isUnfollowing);
if($exec==true){
    $response->status=true;
    $response->message='Successful';
}else{
    $response->status=false;

    $response->message='Unable to add items to database';
}
  
}
header('Content-type: application/json');
echo json_encode($response);
 

