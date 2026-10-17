<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error = '';



if (isset($_POST['new_deal'])) {
    $paymentRef = $_POST['payment_ref'];
    $amount = $_POST['amount'];
    $agentId = $_POST['agentId'];
    $customerId = $_POST['customerId'];
    $inspectionDate = $_POST['inspection_date'];
    $inspectionTime = $_POST['inspection_time'];
    $customerName = $_POST['customer_name'];
    $propertyId = $_POST['property_id'];
    $propertyTitle = $_POST['property_title'];

    $exec =  $helper->addOrderDeal($paymentRef, $amount, $agentId, $customerId, $inspectionDate, $inspectionTime, $customerName, $propertyId, $propertyTitle);
    if ($exec == true) {
        $response->status = true;
        $response->message = 'Successful';
    } else {
        $response->status = false;

        $response->message = 'Unable to add items to database';
    }
} else if (isset($_POST['update_status'])) {
    $dealId = $_POST['deal_id'];
    $newStatus = $_POST['new_status'];

    $exec = $helper->updateDealStatus($newStatus, $dealId);
    if ($exec == true) {
        $response->status = true;
        $response->message = 'Successful';
    } else {
        $response->status = false;

        $response->message = 'Unable to change deal status';
    }
} else if (isset($_POST['reschedule_deal'])) {
    // Sent by the app's "Manage inspection" sheet.
    $dealId = $_POST['deal_id'] ?? null;
    $date = trim($_POST['inspection_date'] ?? '');
    $time = trim($_POST['inspection_time'] ?? '');

    if ($dealId && $date !== '' && $time !== '' && $helper->rescheduleDeal($dealId, $date, $time)) {
        $response->status = true;
        $response->message = 'Successful';
    } else {
        $response->status = false;
        $response->message = 'Unable to reschedule inspection';
    }
} else {
    $response->status = false;

    $response->message = 'Unauthorized';
}
header('Content-type: application/json');
echo json_encode($response);
