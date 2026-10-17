<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error='';
if(isset($_POST['userId'])){
    $currentUserId =$_POST['currentUserId'];
    $userId = $_POST['userId'];
    $result = $helper->getFollowers($userId);

    $response->status='Success';
$response->data=$result;
}else{
    $response->status = 'unauthorized';
}

header('Content-type: application/json');
echo json_encode($response);