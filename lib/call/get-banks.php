<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->data = null;
$response->message = '';
if (isset($_POST['ownerId'])) {
    $ownerId = $_POST['ownerId'];
    $result = $helper->getUserBanks($ownerId);

    $response->status = true;
    $response->message = 'Successful';
    $response->data = $result;
} else {
    $response->status = false;
    $response->data = null;
    $response->message = 'unauthorized';
}

header('Content-type: application/json');
echo json_encode($response);
