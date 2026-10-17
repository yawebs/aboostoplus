<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error='';
if(isset($_POST['propertyId'])){
    $propertyId =$_POST['propertyId'];
    $comments = $helper->getComments($propertyId);

    $response->status='Success';
$response->data=$comments;
}else{
    $response->status = 'unauthorized';
}

header('Content-type: application/json');
echo json_encode($response);