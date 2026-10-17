<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->data = null;
$response->message = '';

if (isset($_POST['delete_item'])) {
    $propertyId = $_POST['property_id'];
    $ownerId = $_POST['owner_id'];
    $exec = $helper->deleteProperty($propertyId, $ownerId);
    if ($exec == true) {
        $response->status = true;
        $response->message = 'Successful';
    } else {
        $response->status = false;

        $response->message = 'Unable to delete item currently please try again leta';
    }
}
header('Content-type: application/json');
echo json_encode($response);
