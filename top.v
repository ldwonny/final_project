`timescale 1ns / 1ps

module top (
    input clk,
    input reset,
    input next,
    input hit,
    input stand,
    input double,
    input split,
    input bet_8,
    input bet_4,
    input bet_2,
    input bet_1,
    input [2:0] test,
    output reg [5:0] player_current_score,      // display
    output reg [5:0] player_new_card,           // display
    output reg [5:0] player_current_score_split,
    output reg [5:0] player_new_card_split,
    output reg [5:0] dealer_current_score,
    output reg [4:0] current_coin,
    output reg can_split,
    output reg Win,
    output reg Lose,
    output reg Draw
);

    // Internal Signals
    wire [3:0] card1_out;
    wire [3:0] card2_out;
    reg on;

    // Instantiate the card_generation module
    card_generation card_gen (
        .clk(clk),
        .reset(reset),
        .on(on),
        .test(test),
        .card1_out(card1_out),
        .card2_out(card2_out)
    );

    // Define game phases
    reg [3:0] game_phases;
    reg double_check;
   
    // Define dealer cards
    reg [5:0] dealer_card1;
    reg [5:0] dealer_card2;

    // Bet amount
    reg [4:0] bet_coin;
    reg [4:0] bet_coin_2;
    reg Win2;
    reg Lose2;
    reg Draw2;
    
    reg [5:0] c1; // recent card
    reg [5:0] c2;
    reg [5:0] c3;
    reg [5:0] c4;
    reg [5:0] sum; // current sum
    reg [5:0] sum2;
    
    
    // Reset logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            game_phases = 0;
            bet_coin = 0;
            bet_coin_2 = 0;
            current_coin = 30; // Initial amount
            dealer_card1 = 0;
            dealer_card2 = 0;
            double_check = 0;
            c1 = 0;
            c2 = 0;
            c3 = 0;
            c4 = 0;
            sum = 0;
            sum2 = 0;
            Win2 = 0;
            Lose2 = 0;
            Draw2 = 0;
                      
            player_current_score = 0;   // display
            player_new_card = 0;
            player_current_score_split = 0;
            player_new_card_split = 0;
            
            dealer_current_score = 0;
            
            can_split = 0;
            Win = 0;
            Lose = 0;
            Draw = 0;
        end
    end

// ==========================================================================================================================

    // Betting phase
    always @(posedge clk) begin
        if (game_phases == 0) begin
            bet_coin = bet_8 * 8 + bet_4 * 4 + bet_2 * 2 + bet_1;
            
            player_current_score = 0;   // "b" diplay
            player_new_card = current_coin;
        end
    end

    // Dealer card draw 
    
    always @(posedge next) begin
        // Dealer card setting
        if (game_phases == 0) begin
            dealer_card1 = 1; // Hard-coded
            dealer_card2 = 2;
            dealer_current_score = dealer_card1 + dealer_card2 + 10 * (dealer_card1 == 1 || dealer_card2 == 1);
            
            player_current_score = 0;   // "d" diplay
            player_new_card = dealer_card2;

            game_phases = 1;
        end 

   // Player card draw
        else if (game_phases == 1) begin
            on = 1;
            #10;
            c1 = card1_out;
            c2 = card2_out;
            on = 0; // Deactivate
            
            sum = c1 + c2 + 10 * (c1 == 1 || c2 == 1);
            can_split = (c1 == c2);
            
            player_current_score = c1; // display
            player_new_card = c2;
            
            if(sum == 21) begin
                game_phases = 12;
                bet_coin = bet_coin * 2;
            end
            else game_phases = 2; // next
        end
    end


// ==========================================================================================================================
// MAIN PHASE


    // Hit 
    always @(posedge hit) begin
        if (game_phases == 2) begin
            double_check = 1;
            can_split = 0;
            on = 1;
            #10;
            c1 = card1_out;
            on = 0;
            
            player_current_score = sum;  // display

            if (c1 == 1 && sum < 11) begin
                sum = sum + c1 + 10;
            end else begin
                sum = sum + c1;
            end
            
            player_new_card = c1;  // new card display

            if (sum > 21) begin  // burst
                Lose = 1;  
                game_phases = 15;
            end else begin
                game_phases = 2;  // one more player turn
            end
        end
        
        else if (game_phases == 4) begin
            double_check = 1;
                
            on = 1;
            #10;
            c1 = card1_out;
            on = 0;
            
            player_current_score = sum;  // display
            player_new_card = c1;  // new card display

            if (c1 == 1 && sum < 11) begin
                sum = sum + c1 + 10;
            end else begin
                sum = sum + c1;
            end
            

            if (sum > 21) begin  // burst
                Lose = 1;  
                game_phases = 8;    // Split 2 turn
            end else begin
                game_phases = 4;  // Split 1 turn
            end
        end

        else if (game_phases == 6) begin
            double_check = 1;
                
            on = 1;
            #10;
            c3 = card1_out;
            on = 0;
            
            player_current_score = sum2;  // display
            player_new_card = c3;  // new card display

            if (c3 == 1 && sum2 < 11) begin
                sum2 = sum2 + c3 + 10;
            end else begin
                sum2 = sum2+ c3;
            end
            

            if (sum2 > 21) begin  // Split 2 burst
                Lose2 = 1;  
                game_phases = 15;    // Split 2 turn
            end else begin
                game_phases = 6;  // Split 2 turn
            end
        end        
    end

    // Stand
    always @(posedge stand) begin    
        if (game_phases == 2) begin
             double_check = 1;
             can_split=0;
             game_phases = 11;  // Dealer turn
        end
        
        else if (game_phases == 4) begin
             double_check = 1;
             game_phases = 8;  // Split 2 turn
        end
        
        else if (game_phases == 6) begin
             double_check = 1;
             game_phases = 11;  // Split 2 end
        end
    end


    always @(posedge double) begin
        if (game_phases == 2 && double_check == 0) begin
            bet_coin = bet_coin * 2;
            double_check = 1;
            can_split = 0;
            
            on = 1;
            #10;
            c1 = card1_out;
            on = 0;
            player_current_score = sum;  // display

            if (c1 == 1 && sum < 11) begin
                sum = sum + c1 + 10;
            end else begin
                sum = sum + c1;
            end
            player_new_card = c1;  // new card display

            if (sum > 21) begin  // burst
                Lose = 1;  
                game_phases = 15;
            end else begin
                game_phases = 12;  // Dealer turn
            end 
        end
        
        else if (game_phases == 4 && double_check == 0) begin
            bet_coin = bet_coin * 2;
            double_check = 1;
            can_split = 0;
            
            on = 1;
            #10;
            c1 = card1_out;
            on = 0;
            player_current_score = sum;  // display

            if (c1 == 1 && sum < 11) begin
                sum = sum + c1 + 10;
            end else begin
                sum = sum + c1;
            end
            player_new_card = c1;  // new card display

            if (sum > 21) begin  // burst
                Lose = 1;  
                game_phases = 8;
            end else begin
                game_phases = 8;  // Split 2 turn
            end 
        end        
        
        else if (game_phases == 6 && double_check == 0) begin
            bet_coin_2 = bet_coin_2 * 2;
            double_check = 1;
            can_split = 0;
            
            on = 1;
            #10;
            c3 = card1_out;
            on = 0;
            player_current_score = sum2;  // display

            if (c3 == 1 && sum2 < 11) begin
                sum2 = sum2 + c3 + 10;
            end else begin
                sum2 = sum2 + c3;
            end
            player_new_card = c3;  // new card display

            if (sum2 > 21) begin  // burst
                Lose2 = 1;  
                game_phases = 15;
            end else begin
                game_phases = 12;  // Split 2 end
            end 
        end 
        
    end

// ====================================================================================================

    // Dealer 2nd phase (end)
    always @(posedge clk) begin
        if (game_phases == 11) begin
            if (dealer_current_score < 17) begin
                dealer_card1 = 2;    // Hard-coded
                
                if (dealer_card1 == 1 && dealer_current_score < 11) begin
                     dealer_current_score = dealer_current_score + dealer_card1 + 10;
                end else begin
                     dealer_current_score = dealer_current_score + dealer_card1;
                end
            end 
            
            else begin
                if (dealer_current_score > 21) begin
                    Win = 1;
                    Win2 = 1;
                end else if (dealer_current_score > sum && sum <= 21 ) begin
                    Lose = 1; 
                end else if (dealer_current_score < sum && sum <= 21) begin
                    Win = 1; 
                end else if (dealer_current_score == sum && sum <= 21) begin
                    Draw = 1;
                 
                end else if (dealer_current_score > sum2 && sum2 <= 21) begin
                    Lose2 = 1; 
                end else if (dealer_current_score < sum2 && sum2 <= 21) begin
                    Win2 = 1; 
                end else if (dealer_current_score == sum2 && sum2 <= 21) begin
                    Draw2 = 1;
                end               
           
                
                game_phases = 15; // Always end 
                
                player_current_score = 0; // Dealer
                player_new_card = dealer_current_score;
            end
        end 
    end

// ===============================================================================================
// Split system

    always @(posedge split) begin
        if(can_split==1 && game_phases == 2)begin
            can_split=0;
            c3=c2;      // copy
            bet_coin_2 = bet_coin;            
            
            on = 1;
            #10;
            c2 = card1_out;
            on = 0;         // Deactivate
            sum = c1 + c2 + 10 * (c1 == 1 || c2 == 1);   // split 2 draw further
                        
            player_current_score = c1; // display
            player_new_card = c2;
            
            game_phases = 4;
        end  
    end
    
    always @(negedge next) begin
        if(game_phases == 8) begin
            double_check=0;
            on = 1;
            #10;
            c4 = card1_out;
            on = 0;         // Deactivate
            sum2 = c3 + c4 + 10 * (c3 == 1 || c4 == 1);   // split 2 
                        
            player_current_score = c3; // display
            player_new_card = c4;
            
            game_phases = 6;        
        end
    end
    

 // ===============================================================================================
 // Result phase
    always @(posedge next) begin    
        if (game_phases == 12) game_phases = 11;  
        
        else if (game_phases == 15) begin
            if (Win) begin
                current_coin = current_coin + bet_coin;
            end else if (Lose) begin
                current_coin = current_coin - bet_coin;
            end
            
            if (Win2) begin
                current_coin = current_coin + bet_coin_2;
            end else if (Lose2) begin
                current_coin = current_coin - bet_coin_2;
            end
            
            
            player_current_score = 0; // Diplay empty LED ON
            player_new_card = 0;
            
            game_phases = 14;

        end
               
        
        else if (game_phases == 14) begin
            Win <= 0;
            Lose <= 0;
            Draw <= 0;
            
            Win2 <= 0;
            Lose2 <= 0;
            Draw2 <= 0;
            bet_coin_2 <=0;
                  
            game_phases = 0;  // Re-game
        end
    end

endmodule
