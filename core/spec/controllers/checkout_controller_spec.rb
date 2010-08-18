require 'spec_helper'

describe CheckoutController do

  # let(:order) { mock_model Order, :complete? => false, :empty? => false, :state => "confirm", :state= => nil, :can_next? => true, :update_attribute => true, :update_attributes => true, :
  #                                 :payment? => false, :next! => true, :bill_address => mock_model(Address), :ship_address => mock_model(Address) }
  let(:order) { Order.create }
  before do
    order.stub!(:empty?).and_return(false)
    # Order.stub!(:find_by_id).and_return order
    controller.stub!(:current_order).and_return(order)
  end

  it "should understand checkout routes" do
    assert_routing("/checkout/delivery", {:controller => "checkout", :action => "edit", :state => "delivery"})
    assert_routing("/checkout/update/delivery", {:controller => "checkout", :action => "update", :state => "delivery"})
  end

  context "#edit" do

    it "should redirect to the cart path if order.empty?" do
      order.stub(:empty?).and_return true
      get :edit, { :state => "delivery" }
      response.should redirect_to cart_path
    end

    it "should redirect to the cart path if current incompelte order can't be found" do
      controller.stub!(:current_order).and_return(nil)
      get :edit, { :state => "delivery" }
      response.should redirect_to cart_path
    end

    it "should change to the requested state" do
      order.should_receive(:state=).with("payment").and_return true
      get :edit, { :state => "payment" }
    end

  end

  context "#update" do

    it "should remove completed order from the session" do
      order.stub(:complete?).and_return(true)
      post :update, {:state => "confirm"}
      session[:order_id].should be_nil
    end

    context "save successful" do
      before do
        order.stub(:update_attribute).and_return true
        order.should_receive(:update_attributes).and_return true
      end

      it "should assign order" do
        post :update, {:state => "confirm"}
        assigns[:order].should_not be_nil
      end

      it "should change to requested state" do
        order.should_receive(:update_attribute).with('state', 'confirm')
        post :update, {:state => "confirm"}
      end

      context "with next state" do
        before { order.stub(:state).and_return("delivery") }

        it "should advance the state" do
          order.should_receive(:next).and_return true
          post :update, {:state => "delivery"}
        end

        it "should redirect the next state" do
          order.update_attribute(:state, 'confirm')
          post :update, {:state => "confirm"}
          response.should redirect_to checkout_state_path("complete")
        end
      end

      context "with no more steps (would only happen on refresh)" do
        before { order.stub(:can_next?).and_return false }

        it "should not advance the next state" do
          order.should_not_receive(:next)
          post :update, {:state => "confirm"}
        end

        it "should render the current state" do
          post :update, {:state => "confirm"}
          response.should render_template :edit
        end
      end
    end

    context "save unsuccessful" do
      before { order.should_receive(:update_attributes).and_return false }

      it "should assign order" do
        post :update, {:state => "confirm"}
        assigns[:order].should_not be_nil
      end

      it "should not change the order state" do
        order.should_not_receive(:update_attribute)
        post :update, { :state => 'confirm' }
      end

      it "should render the edit template" do
        post :update, { :state => 'confirm' }
        response.should render_template :edit
      end
    end

    context "when order is complete" do
      before { controller.stub! :current_order => nil }
      it "should not change the state if order is completed" do
        order.should_not_receive(:update_attribute)
        post :update, {:state => "confirm"}
      end

      it "should redirect to the cart_path" do
        post :update, {:state => "confirm"}
        response.should redirect_to cart_path
      end
    end

  end
end
