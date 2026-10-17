<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error = '';



if (isset($_POST['payment_details'])) {
    $agentId = $_POST['agentId'];
    $amount = $_POST['amount'];
    $customerId = $_POST['customerId'];

    $paymentRef = $_POST['payment_ref'];



    $exec =  $helper->addPaymentDetails($agentId, $amount, $customerId, $paymentRef);
    if ($exec == true) {
        $response->status = true;
        $response->message = 'Successful';
    } else {
        $response->status = false;

        $response->message = 'Unable to add items to database';
    }
} else if (isset($_POST['update_balances'])) {
    $ownerId = $_POST['ownerId'];
    $amount = $_POST['amount'];
    $checkWalletExist = $helper->checkWalletExists($ownerId);
    if ($checkWalletExist == 0) {
        $exec =  $helper->setBalance($ownerId, $amount);
        if ($exec == true) {
            $response->status = true;
            $response->message = 'Successful';
        } else {
            $response->status = false;

            $response->message = 'Unable to update balance';
        }
    } else {
        $exec =   $helper->updateBalance($ownerId, $amount);
        if ($exec == true) {
            $response->status = true;
            $response->message = 'Successful';
        } else {
            $response->status = false;

            $response->message = 'Unable to update balance';
        }
    }
} else if (isset($_POST['get_wallet_balance'])) {
    $ownerId = $_POST['ownerId'];
    $result = $helper->getWalletBalance($ownerId);
    $response->status = true;
    $response->message = 'Successful';
    $response->data = $result;
} else if (isset($_POST['get_platform_charges'])) {
    $result = $helper->getCharges();
    $response->status = true;
    $response->message = 'Successful';
    $response->data = $result;
} else {
    $response->status = false;

    $response->message = 'unathorized action';
}
header('Content-type: application/json');
echo json_encode($response);
