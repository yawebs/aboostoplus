<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error = '';



if (isset($_POST['upload_house'])) {
    $desc = $_POST['description'];
    $title = $_POST['title'];
    $amount = $_POST['amount'];

    $ownerId = $_POST['ownerId'];
    $category = $_POST['category'];
    $location = $_POST['location'];
    $requirements = $_POST['requirements'];
    $userType = $_POST['userType'];
    $rooms = $_POST['rooms'];
    $bathrooms = $_POST['bathrooms'];
    $imageUrls = $_POST['imageUrls'];
    $userName = $_POST['userName'];
    $community = $_POST['community'];
    $colorCode = $_POST['color_code'];
    $taggedUser = $_POST['tagged_userId'];
    $isHouse = $_POST['is_house'];
    $plot = $_POST['property_plot'];
    $city = $_POST['hCity'];
    $cautionFee = $_POST['cautionFee'];
    $legalFee = $_POST['legalFee'];
    $agentFee = $_POST['agentFee'];
    $isVideo = $_POST['isVideo'];
    $propertyOwnerData = $_POST['propertyOwnerData'];



    $exec =  $helper->addHouse($title, $desc, $category, $ownerId, $location, $requirements, $amount, $userType, $imageUrls, $rooms, $bathrooms, $userName, $community, $colorCode, $taggedUser, $isHouse, $plot, $city, $cautionFee, $legalFee, $agentFee, $isVideo, $propertyOwnerData);
    if ($exec == true) {
        $response->status = true;
        $response->message = 'Successful';
        // Push "new match" notifications to users with matching search alerts.
        require_once __DIR__ . '/search_alerts_lib.php';
        aboostoplusNotifySearchAlerts($pdo, (int) $pdo->lastInsertId());
    } else {
        $response->status = false;

        $response->message = 'Unable to add items to database';
    }
} else if (isset($_POST['product_upload'])) {
    $name = $_POST['item_name'];
    $desc = $_POST['item_desc'];
    $category = $_POST['category'];
    $ownerId = $_POST['ownerId'];
    $area = $_POST['area'];
    $state = $_POST['item_state'];
    $amount = $_POST['amount'];
    $itemOwnerData = $_POST['item_owner_data'];
    $images = $_POST['images'];



    $exec =  $helper->productUpload($name, $desc, $area, $amount, $itemOwnerData, $category, $state, $images, $ownerId);
    if ($exec == true) {
        $response->status = true;
        $response->message = 'Successful';
    } else {
        $response->status = false;

        $response->message = 'Unable to add items to database';
    }
}

header('Content-type: application/json');
echo json_encode($response);
