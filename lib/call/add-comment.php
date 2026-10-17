<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error = '';



$propertyId = $_POST['propertyId'];
$commenterId = $_POST['commenterId'];
$comment = $_POST['comment'];
$commenterImage = $_POST['commenterImage'];
$commenterName = $_POST['commenterName'];



$exec =  $helper->addComment($propertyId, $commenterId, $comment, $commenterName, $commenterImage);
if ($exec == true) {
    $response->status = true;
    $response->message = 'Successful';
} else {
    $response->status = false;

    $response->message = 'Unable to add items to database';
}

header('Content-type: application/json');
echo json_encode($response);
