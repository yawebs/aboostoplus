<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error = '';

if (isset($_POST['send_report'])) {
    $reporterId = $_POST['reporterId'];
    $propertyId = $_POST['propertyId'];
    $report = $_POST['report'];
    $propertyOwnerId = $_POST['propertyOwnerId'];

    $exec =  $helper->sendReport($propertyId, $reporterId, $propertyOwnerId, $report);
    if ($exec == true) {
        $response->status = true;
        $response->message = 'Successful';
    } else {
        $response->status = false;

        $response->message = 'Unable to add items to database';
    }
} else {
    $response->status = false;

    $response->message = 'Unauthorized';
}
header('Content-type: application/json');
echo json_encode($response);
